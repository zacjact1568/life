import 'package:flutter/material.dart';
import 'package:life/home/widgets.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  // 用于描述如何根据子 Widget 来显示自己
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life',
      theme: ThemeData(
        primaryColor: Colors.blueAccent,
      ),
      home: HomeWidget(),
    );
  }
}
