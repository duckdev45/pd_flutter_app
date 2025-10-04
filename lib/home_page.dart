// lib/home_page.dart

import 'package:flutter/material.dart';
import 'announcement_page.dart'; // 引入公告頁
import 'clock_in_page.dart'; // 引入打卡頁
import 'settings_page.dart'; // 引入設定頁

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 記住目前選擇的是哪個頁面的索引 (index)
  // 0: 公告, 1: 打卡, 2: 設定
  // 預設是 1 (打卡頁面)，所以一進來就是打卡頁
  int _selectedIndex = 1;

  // 把三個頁面放進一個 List 裡，方便我們用 index 切換
  static const List<Widget> _widgetOptions = <Widget>[
    AnnouncementPage(),
    ClockInPage(),
    SettingsPage(),
  ];

  // 當使用者點擊底下按鈕時，這個方法會被觸發
  void _onItemTapped(int index) {
    // 用 setState 更新 _selectedIndex 的值，Flutter 會自動重繪畫面
    setState(() {
      _selectedIndex = index;
    });
  }

  // 根據選擇的 index，決定 AppBar 要顯示什麼標題
  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return '最新公告';
      case 1:
        return '打卡';
      case 2:
        return '設定';
      default:
        return '磐鼎營造';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()), // 標題會根據頁面切換
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // 拿掉預設的返回箭頭
      ),
      // body 的內容會根據 _selectedIndex 從 _widgetOptions List 中選取
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      // 關鍵！底部的導航欄
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: '公告'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: '打卡'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
        currentIndex: _selectedIndex, // 目前選中的按鈕
        selectedItemColor: Colors.orange, // 選中時的顏色
        onTap: _onItemTapped, // 點擊事件
      ),
    );
  }
}
