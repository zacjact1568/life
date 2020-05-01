import 'package:life/util/time.dart';
import 'package:life/util/model.dart';
import 'package:sqflite/sqflite.dart';
import 'manager.dart';

const _POST_TABLE = 'blog_post';

const TITLE = 'title';
const EXCERPT = 'excerpt';
const CREATED_AT = 'created_at';
const UPDATED_AT = 'updated_at';
const LABEL = 'label';

/// 数据库迁移语句
const MIGRATION = const [
  '''
  CREATE TABLE $_POST_TABLE(
    $TITLE VARCHAR(100),
    $EXCERPT TEXT,
    $CREATED_AT DATETIME,
    $UPDATED_AT DATETIME,
    $LABEL VARCHAR(100) PRIMARY KEY
  )
  ''',
];

/// 删除表中所有 post 数据，然后插入 [postList] 中所有数据
Future<void> deleteAllPostsAndReplacedBy(List<Post> postList) async {
  final db = await getDatabase();
  await db.transaction((txn) async {
    await txn.delete(_POST_TABLE);
    // 不用 batch，因为 batch commit 在事务 commit 之后
    // 这样可能会有问题？
    for (final post in postList) {
      await txn.insert(_POST_TABLE, post.toMap(DateTimeStringType.LOCAL));
    }
  });
}

Future<void> insertAllPosts(List<Post> postList) async {
  final db = await getDatabase();
  await db.transaction((txn) async {
    for (final post in postList) {
      await txn.insert(
        _POST_TABLE,
        post.toMap(DateTimeStringType.LOCAL),
        // 插入相同主键的 post 时将其替换
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  });
}

/// 获取第 [page] 页的 post 数据
Future<List<Post>> getPostListFromLocal(int page) async {
  final db = await getDatabase();
  final countMapList = await db.rawQuery('SELECT COUNT(*) FROM $_POST_TABLE');
  final count = countMapList[0]['COUNT(*)'];
  final offset = (page - 1) * PAGE_SIZE;
  if (offset >= count) {
    // 数据库中没有第 page 页的数据
    return null;
  }
  final List<Map<String, dynamic>> postMapList = await db.query(
    _POST_TABLE,
    // 按创建时间降序排列
    orderBy: '$CREATED_AT DESC',
    limit: PAGE_SIZE,
    offset: offset,
  );
  return List.generate(postMapList.length, (index) => Post.fromMap(
      postMapList[index], DateTimeStringType.LOCAL
  ));
}
