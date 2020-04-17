import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:life/util/secret.dart' show token;
import 'models.dart';

const url = 'https://life.zackzhang.net/blog/get-post-list/';

Future<List<Post>> getPostList() async {
  final response = await http.get(url, headers: {'Authorization': 'Token $token'});
  // response.body 会根据 content-type 中的 charset
  // 来将原始 body 字节码（response.bodyBytes）转换为字符串
  // 但后端返回的 content-type 中没有 charset，会导致中文乱码
  response.headers['content-type'] += '; charset=utf-8';
  if (response.statusCode == 200) {
    // JSON -> Map -> MapList -> List
    final postMapList = json.decode(response.body)['results'];
    // 声明空集合时必须指定类型，不然会推断成 dynamic
    var postList = <Post>[];
    for (var postMap in postMapList) {
      postList.add(Post.fromMap(postMap));
    }
    return postList;
  } else {
    // TODO 给出提示（response.body）而不是抛出异常
    throw Exception('Failed');
  }
}
