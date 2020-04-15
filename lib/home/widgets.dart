import 'package:flutter/material.dart';
import 'package:life/blog/widgets.dart';

class HomeWidget extends StatefulWidget {
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<HomeWidget> {

  int _selectedIndex = 0;
  static const _optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  final _widgetOptions = <Widget>[
    BlogWidget(),
    Text('音乐', style: _optionStyle),
    Text('影视', style: _optionStyle),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 每次调用 setState 时都会重新调用该方法
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Life')),
      body: Center(child: _widgetOptions[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.subject),
            title: Text('博客'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            title: Text('音乐'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            title: Text('影视'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}
