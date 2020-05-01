import 'package:flutter/material.dart';

import 'model/manager.dart';

/// 刷新的状态
enum _RefreshingStatus {
  // 闲置（起始状态）
  INIT_IDLE,
  // 首次、初始刷新中（全屏圆形加载指示器，不显示列表）
  INIT_REFRESHING,
  // 首次刷新失败（全屏中心重试按钮）
  INIT_FAILED,
  // 列表闲置（显示列表）
  // 可能是：
  // 首次、初始、列表刷新成功
  // 初始刷新失败（回退显示数据库数据）
  // 列表刷新失败（不作任何改变）
  LIST_IDLE,
  // 列表刷新中（RefreshIndicator 自动显示下拉刷新指示器，不需要响应此状态变化）
  LIST_REFRESHING,
}

/// 加载更多的状态
enum _LoadingMoreStatus {
  // 闲置
  IDLE,
  // 加载中
  LOADING,
  // 加载成功，有更多
  NEW_LIST,
  // 加载失败
  FAILED,
  // 已全部加载（无更多）
  NO_MORE,
}

class BlogWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PostListWidget();
}

class PostListWidget extends StatefulWidget {
  @override
  PostListState createState() => PostListState();
}

class PostListState extends State<PostListWidget> {

  final _postList = <Post>[];

  var _refreshingStatus = _RefreshingStatus.INIT_IDLE;
  var _loadingMoreStatus = _LoadingMoreStatus.IDLE;

  int _lastPage = 0;

  final _scrollController = ScrollController();

  void _scrollListener() {
    // 滚动到底部执行加载更多
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMore();
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
    _scrollController.addListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    switch (_refreshingStatus) {
      case _RefreshingStatus.INIT_REFRESHING:
        // 初始刷新中
        // 显示圆形加载指示器
        return CircularProgressIndicator();
      case _RefreshingStatus.INIT_FAILED:
        // 初始刷新失败
        // 显示重新加载按钮
        return Center(
          child: FlatButton(
            textColor: Colors.blueAccent,
            onPressed: _refresh,
            child: Text('重试'),
          ),
        );
      case _RefreshingStatus.LIST_IDLE:
      case _RefreshingStatus.LIST_REFRESHING:
        // 初始刷新成功，或正在刷新（RefreshIndicator 有刷新动画）
        // 显示列表
        return RefreshIndicator(
          child: _buildPostList(),
          onRefresh: _refresh,
        );
      default:
        throw ArgumentError.value(_refreshingStatus, '_refreshingStatus');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    // TODO 如果在刷新或加载更多，停止
    super.dispose();
  }

  Widget _buildPostList() {
    return ListView.builder(
      itemCount: _postList.length + 1,
      itemBuilder: (context, index) {
        if (index == _postList.length) {
          return Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              height: 40.0,
              child: Center(
                child: _buildLoadingMoreArea(),
              ),
            ),
          );
        } else {
          return _buildPostItem(_postList[index]);
        }
      },
      controller: _scrollController,
      // 不加这个 physics 的话
      // 在列表不超出屏幕，且设置了上面的 controller 的时候
      // 无法触发下拉刷新
      physics: AlwaysScrollableScrollPhysics(),
    );
  }

  Widget _buildPostItem(Post post) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 2.0)),
                  Text(
                    post.excerpt,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.only(top: 10.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Icon(
                    Icons.today,
                    size: 14.0,
                    color: Colors.black38,
                  ),
                  const Padding(padding: EdgeInsets.only(left: 3.0)),
                  Text(
                    post.creationDate,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 0.0),
      ],
    );
  }

  Widget _buildLoadingMoreArea() {
    switch (_loadingMoreStatus) {
      case _LoadingMoreStatus.IDLE:
      case _LoadingMoreStatus.NEW_LIST:
        // 闲置状态或成功加载新数据
        return Text('上拉加载更多');
      case _LoadingMoreStatus.LOADING:
        // 加载中
        return CircularProgressIndicator();
      case _LoadingMoreStatus.FAILED:
        // 加载失败
        return Text('上拉再次尝试加载');
      case _LoadingMoreStatus.NO_MORE:
        // 加载完成
        return Text('共 ${_postList.length} 篇文章');
      default:
        throw ArgumentError.value(_loadingMoreStatus, '_loadingMoreStatus');
    }
  }

  /// 刷新
  Future<void> _refresh() async {
    // 如果在加载更多，不响应
    if (_loadingMoreStatus == _LoadingMoreStatus.LOADING) return;
    // 此时 _refreshingStatus 只可能是 INIT_IDLE 或 INIT_FAILED 或 LIST_IDLE
    setState(() {
      if (_refreshingStatus == _RefreshingStatus.INIT_IDLE
          || _refreshingStatus == _RefreshingStatus.INIT_FAILED) {
        // 如果当前为初始闲置或初始失败状态
        // 切换为初始刷新
        _refreshingStatus = _RefreshingStatus.INIT_REFRESHING;
      } else {
        // 如果当前为列表闲置状态
        // 切换为列表刷新
        // PS：可以不包含在 setState 中
        // 因为没有 Widget 状态的切换是依赖 LIST_REFRESHING 的
        _refreshingStatus = _RefreshingStatus.LIST_REFRESHING;
      }
    });
    // 此时 _refreshingStatus 只可能是 INIT_REFRESHING 或 LIST_REFRESHING
    // 始终请求第一页
    final pack = await getPostList(1, _refreshingStatus == _RefreshingStatus.INIT_REFRESHING);
    setState(() {
      if (pack.partialList != null) {
        // 刷新成功
        // 可能是一次性网络或数据库成功
        // 或网络失败后，从数据库中取得缓存
        _postList.replaceRange(0, _postList.length, pack.partialList);
        if (_postList.length == pack.totalCount) {
          // 说明数据已全部加载（只有一页）
          _loadingMoreStatus = _LoadingMoreStatus.NO_MORE;
        } else {
          // 否则需要恢复未全部加载的状态
          // 否则当数据全部加载后再刷新
          // 底部 LoadingArea 不会变（共 * 篇文章）
          _loadingMoreStatus = _LoadingMoreStatus.IDLE;
        }
        // 无论是初始刷新还是列表刷新，都切换为列表闲置状态
        _refreshingStatus = _RefreshingStatus.LIST_IDLE;
        // 页数设为第一页
        _lastPage = 1;
      } else {
        // 刷新失败
        // 可能是网络失败后，数据库中也没有缓存
        if (_refreshingStatus == _RefreshingStatus.INIT_REFRESHING) {
          // 如果是初始刷新，切换为初始失败
          _refreshingStatus = _RefreshingStatus.INIT_FAILED;
        } else {
          // 如果是列表刷新，切换为列表闲置
          _refreshingStatus = _RefreshingStatus.LIST_IDLE;
        }
      }
    });
    if (pack.error != null) {
      // 可能是网络失败后，从数据库中取得缓存
      // 或网络失败后，数据库中也没有缓存
      // 有错误信息，弹对话框
      _showErrorDialog(pack.error);
    }
  }

  /// 加载更多
  Future<void> _loadMore() async {
    // 此时 _loadingMoreStatus 不可能是 NEW_LIST
    // 如果已经在加载，或已加载完毕，或不在刷新的列表闲置状态，不响应
    if (_loadingMoreStatus == _LoadingMoreStatus.LOADING
        || _loadingMoreStatus == _LoadingMoreStatus.NO_MORE
        || _refreshingStatus != _RefreshingStatus.LIST_IDLE) return;
    // 此时 _loadingMoreStatus 只可能是 IDLE 和 FAILED
    // 切换为正在加载
    setState(() => _loadingMoreStatus = _LoadingMoreStatus.LOADING);
    // 请求下一页
    final pack = await getPostList(_lastPage + 1, false);
    setState(() {
      if (pack.partialList != null) {
        // 加载成功
        // 可能是一次性网络或数据库成功
        // 或网络失败后，从数据库中取得缓存
        _postList.addAll(pack.partialList);
        if (_postList.length == pack.totalCount) {
          // 说明数据已全部加载
          _loadingMoreStatus = _LoadingMoreStatus.NO_MORE;
        } else {
          _loadingMoreStatus = _LoadingMoreStatus.IDLE;
        }
        // 页数设为下一页
        _lastPage++;
      } else {
        // 加载失败
        // 可能是网络失败后，数据库中也没有缓存
        // 如果是初始刷新，切换为初始失败
        _loadingMoreStatus = _LoadingMoreStatus.FAILED;
      }
    });
    if (pack.error != null) {
      // 可能是网络失败后，从数据库中取得缓存
      // 或网络失败后，数据库中也没有缓存
      // 有错误信息，弹对话框
      _showErrorDialog(pack.error);
    }
  }

  /// 显示错误提示对话框
  Future<void> _showErrorDialog(String content) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('错误'),
          content: Text(content),
          actions: <Widget>[
            FlatButton(
              child: Text('好'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      }
    );
  }
}
