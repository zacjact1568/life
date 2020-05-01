import 'package:life/util/time.dart';
import 'package:life/util/model.dart';
import 'network.dart';
import 'database.dart';
import 'preference.dart';

/// 每页加载的数据量（与后端保持一致）
const PAGE_SIZE = 10;
/// 自动刷新阈值（小时）
const _AUTO_REFRESHING_THRESHOLD = 1;

/// [init] 指示是不是打开 app 的第一次刷新
/// [force] 指示是否强制从网络获取，不会从数据库取任何数据，即使从网络获取失败也是如此
/// 返回的 pack：
/// 一次网络成功或一次数据库成功：totalCount、partialList 有，error 无
/// 一次网络失败且二次数据库成功：totalCount、partialList 和 error 都有
/// 一次网络失败且二次数据库失败：totalCount、partialList 无，error 有
Future<Pack<Post>> getPostList(int page, bool init, {bool force = false}) async {
  // 只通过上次刷新时间来判断是否需要强制从网络获取
  // 在某些情况下会造成加载更多的时候总是不使用数据库缓存
  final lastRefreshingTime = await getPostLastRefreshingTime();
  var status;
  if (lastRefreshingTime == null) {
    // 首次刷新
    // page == 1 & init == true & lastRefreshingTime == null
    status = _GetPostListStatus.FIRST_INIT_REFRESHING;
  } else if (init) {
    // 初始刷新
    // page == 1 & init == true & lastRefreshingTime != null
    status = _GetPostListStatus.INIT_REFRESHING;
  } else if (page == 1) {
    // 下拉刷新
    // page == 1 & init == false & lastRefreshingTime != null
    status = _GetPostListStatus.LIST_REFRESHING;
  } else {
    // 加载更多
    // page >= 2 & init == false & lastRefreshingTime != null
    status = _GetPostListStatus.LOADING_MORE;
  }
  if (force
      || status == _GetPostListStatus.FIRST_INIT_REFRESHING
      || status == _GetPostListStatus.LIST_REFRESHING
      // 当且仅当首次刷新时 lastRefreshingTime 才为 null
      || checkExpired(lastRefreshingTime, _AUTO_REFRESHING_THRESHOLD)) {
    // 如果 force == true，直接强制从网络获取，否则：
    // 当首次刷新或下拉刷新时，需要强制从网络获取
    // 如果不是上述两种情况（即初始刷新和加载更多）
    // 就视上次刷新时间决定是否需要强制从网络获取
    final pack = await getPostListFromNetwork(page);
    if (pack.error == null) {
      // 成功从网络获取
      if (status != _GetPostListStatus.LOADING_MORE) {
        // 如果不是加载更多（即任一种刷新）
        // 将本次刷新时间存入 preference
        await setNowAsPostLastRefreshingTime();
      }
      // 将 post 总数存入 preference
      await setTotalPostCount(pack.totalCount);
      final postList = pack.partialList;
      if (status == _GetPostListStatus.INIT_REFRESHING
          || status == _GetPostListStatus.LIST_REFRESHING) {
        // 初始刷新或下拉刷新
        // 替换本地数据库缓存
        await deleteAllPostsAndReplacedBy(postList);
      } else {
        // 首次刷新或加载更多
        // 将从网络获取的数据插入数据库
        // 如果已存在相同主键的数据，将替换（仅加载更多时）
        await insertAllPosts(postList);
      }
      // pack 中只有 count + list
    } else if (!force && (status == _GetPostListStatus.INIT_REFRESHING
        || status == _GetPostListStatus.LOADING_MORE)) {
      // 网络获取失败，且非强制从网络获取，且为初始刷新或加载更多
      // 才尝试从数据库中获取缓存
      final postList = await getPostListFromLocal(page);
      if (postList != null) {
        // 这个 page 没有超出数据库中存储的数据
        // 将缓存的 post 总数和 post 列表放入 pack
        pack.totalCount = await getTotalPostCount();
        pack.partialList = postList;
        // 给 error 添加说明
        pack.error += '\n但成功从本地缓存中载入';
        // pack 中 count + list + error 都有
      }
      // 如果这个 page 超出了数据库中存储的数据
      // pack 中只有 error
    }
    // 强制从网络获取，或首次刷新从网络获取失败
    // pack 中只有 error
    return pack;
  }
  // 初始刷新或加载更多，且数据库缓存未过期
  // 尝试从数据库获取
  final postList = await getPostListFromLocal(page);
  if (postList != null) {
    // 这个 page 没有超出数据库中存储的数据
    return Pack<Post>.successful(await getTotalPostCount(), postList);
  }
  // 这个 page 超出了数据库中存储的数据
  // 递归调用该函数，设为强制从网络获取
  return await getPostList(page, init, force: true);
}

enum _GetPostListStatus {
  /// 首次刷新：打开 app 的第一次刷新，但以前从未成功刷新过
  FIRST_INIT_REFRESHING,
  /// 初始刷新：打开 app 的第一次刷新，以前成功刷新过
  INIT_REFRESHING,
  /// 下拉刷新：不是打开 app 的第一次刷新
  LIST_REFRESHING,
  /// 加载更多
  LOADING_MORE
}

class Post {
  final String title;
  final String excerpt;
  // 请求列表时不包括 content
  // 所以不初始化它
  // String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String label;

  Post({
    this.title,
    this.excerpt,
    this.createdAt,
    this.updatedAt,
    this.label
  });

  String get creationDate => toDateTimeString(createdAt, DateTimeStringType.DATE);
  String get updatingDate => toDateTimeString(updatedAt, DateTimeStringType.DATE);

  // JSON 反序列化后为 Map<String, dynamic>
  Post.fromMap(Map<String, dynamic> map, DateTimeStringType type): this(
    title: map[TITLE],
    excerpt: map[EXCERPT],
    createdAt: parseDateTimeString(map[CREATED_AT], type),
    updatedAt: parseDateTimeString(map[UPDATED_AT], type),
    label: map[LABEL],
  );

  Map<String, dynamic> toMap(DateTimeStringType type) {
    return {
      TITLE: title,
      EXCERPT: excerpt,
      CREATED_AT: toDateTimeString(createdAt, type),
      UPDATED_AT: toDateTimeString(updatedAt, type),
      LABEL: label,
    };
  }
}
