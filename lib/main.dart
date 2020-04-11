import 'package:flutter/material.dart';

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
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {

  int _selectedIndex = 0;
  static const _optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const _widgetOptions = <Widget>[
    // TODO ListView
    Text('文章', style: _optionStyle),
    Text('音乐', style: _optionStyle),
    Text('影视', style: _optionStyle),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 每次调用 setState 时都会重新运行该方法
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Life')),
      body: Center(child: _widgetOptions[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.subject),
            title: Text('文章'),
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
