import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:life/blog/model/database.dart' as blog;

// SqfliteDatabaseOpenHelper 内部实现了缓存
// 在调用 close 之前，只会在首次调用 openDatabase 时创建 SqfliteDatabase 对象
// 所以可以直接取，不用自己再去缓存一次了
Future<Database> getDatabase() async => await openDatabase(
  join(await getDatabasesPath(), 'life.db'),
  version: 1,
  onCreate: (db, version) {
    db.execute(blog.MIGRATION[0]);
    // 在此创建其他模块的数据库表
  },
  onUpgrade: (db, oldVersion, newVersion) {
    // 在此执行数据库升级语句
  },
);

Future<void> closeDatabase() async => await (await getDatabase()).close();

class Pack<T> {
  int totalCount;
  List<T> partialList;
  String error;

  Pack.successful(this.totalCount, this.partialList);

  Pack.failed(this.error);
}
