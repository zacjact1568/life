import 'dart:math';

import 'package:flutter/material.dart';

class BlogWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PostListWidget();
}

class PostListWidget extends StatefulWidget {
  @override
  PostListState createState() => PostListState();
}

class PostListState extends State<PostListWidget> {

  final nums = [];

  static const _postTitleStyle = TextStyle(fontSize: 18.0);

  Widget _buildPostList() {
    return ListView.builder(
        itemCount: nums.length * 2,
        itemBuilder: (context, i) {
          if (i.isOdd) return Divider();
          final seq = i ~/ 2;
          return _buildPostItem(nums[seq]);
        }
    );
  }

  Widget _buildPostItem(int seq) {
    return ListTile(
      title: Text(
        seq.toString(),
        style: _postTitleStyle,
      ),
    );
  }

  Future<void> _refresh() async {
    // TODO 从网络加载数据
    int next = await _fakeDelay();
    setState(() {
      nums.add(next);
    });
  }

  Future<int> _fakeDelay() {
    return Future.delayed(Duration(seconds: 1), () => Random().nextInt(10));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      child: _buildPostList(),
      onRefresh: _refresh,
    );
  }
}
