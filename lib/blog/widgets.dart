import 'package:flutter/material.dart';

import 'models.dart';
import 'network.dart';

class BlogWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PostListWidget();
}

class PostListWidget extends StatefulWidget {
  @override
  PostListState createState() => PostListState();
}

class PostListState extends State<PostListWidget> {

  final postList = <Post>[];

  static const _postTitleStyle = TextStyle(fontSize: 18.0);

  Widget _buildPostList() {
    return ListView.builder(
      itemCount: postList.length * 2,
      itemBuilder: (context, i) {
        if (i.isOdd) return Divider();
        final seq = i ~/ 2;
        return _buildPostItem(postList[seq]);
      }
    );
  }

  Widget _buildPostItem(Post post) {
    return ListTile(
      title: Text(
        post.title,
        style: _postTitleStyle,
      ),
    );
  }

  Future<void> _refresh() async {
    final newPostList = await getPostList();
    setState(() {
      postList.replaceRange(0, postList.length, newPostList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      child: _buildPostList(),
      onRefresh: _refresh,
    );
  }
}
