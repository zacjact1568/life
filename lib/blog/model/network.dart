import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:life/util/secret.dart' show token;
import 'package:life/util/time.dart';
import 'package:life/util/model.dart';
import 'manager.dart';

Future<Pack<Post>> getPostListFromNetwork(int page) async {
  // TODO 处理非服务器问题（e.g. 无网络、连接不上）
  final response = await http.get(
    'https://life.zackzhang.net/blog/get-post-list/?page=$page',
    headers: {'Authorization': 'Token $token'}
  );
  // response.body 会根据 content-type 中的 charset
  // 来将原始 body 字节码（response.bodyBytes）转换为字符串
  // 但后端返回的 content-type 中没有 charset，会导致中文乱码
  response.headers['content-type'] += '; charset=utf-8';
  int statusCode = response.statusCode;
  // JSON -> Map
  final responseMap = json.decode(response.body);
  if (statusCode == 200) {
    // Map -> MapList -> List
    final postMapList = responseMap['results'];
    // 声明空集合时必须指定类型，不然会推断成 dynamic
    final postList = <Post>[];
    for (var postMap in postMapList) {
      postList.add(Post.fromMap(postMap, DateTimeStringType.NETWORK));
    }
    return Pack<Post>.successful(responseMap['count'], postList);
  } else {
    return Pack<Post>.failed('网络请求失败\n$statusCode：${responseMap['detail']}');
  }
}
