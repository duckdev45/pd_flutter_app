// lib/clock_in_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ClockInPage extends StatefulWidget {
  const ClockInPage({super.key});

  @override
  State<ClockInPage> createState() => _ClockInPageState();
}

class _ClockInPageState extends State<ClockInPage> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    // 初始化 intl 的中文日期格式
    initializeDateFormatting('zh_TW', null);
    _currentTime = DateTime.now();
    // 每秒觸發一次，更新時間
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // 確保 widget 還在畫面上才更新
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    // 頁面銷毀時，取消計時器，避免記憶體洩漏
    _timer.cancel();
    super.dispose();
  }

  // 根據現在時間回傳問候語
  String _getGreeting() {
    final hour = _currentTime.hour;
    if (hour < 12) {
      return '早安';
    } else if (hour < 18) {
      return '午安';
    } else {
      return '晚安';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 'zh_TW' 來顯示中文星期
    final dayFormat = DateFormat('M月d日 EEEE', 'zh_TW');

    return Scaffold(
      backgroundColor: Colors.grey[100], // 給個淺灰色底，凸顯卡片
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: 問候語 & 頭像 ---
            _buildHeader(),
            const SizedBox(height: 30),

            // --- 主功能區：打卡 ---
            _buildClockInCard(dayFormat),
            const SizedBox(height: 30),

            // --- 下方功能區 ---
            _buildFunctionGrid(),
          ],
        ),
      ),
    );
  }

  // Header Widget
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}! 👋',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const Text(
              'Duck', // 這邊未來可以換成真實使用者名稱
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // 打卡卡片 Widget
  Widget _buildClockInCard(DateFormat dayFormat) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左側：日期 & 時間
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayFormat.format(_currentTime),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('HH:mm').format(_currentTime),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              // 右側：打卡按鈕
              ElevatedButton(
                onPressed: () {
                  // TODO: 在這裡處理打卡邏輯
                  print('打卡按下了！時間: $_currentTime');
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(
                    side: BorderSide(color: Colors.white, width: 3),
                  ),
                  padding: const EdgeInsets.all(35),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('打卡'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 功能區 Grid Widget
  Widget _buildFunctionGrid() {
    return GridView.count(
      crossAxisCount: 3,
      // 每行顯示 3 個
      shrinkWrap: true,
      // 讓 GridView 高度自適應內容
      physics: const NeverScrollableScrollPhysics(),
      // 在 SingleChildScrollView 裡，關閉自己的滾動
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildMenuButton(Icons.event_note, '出勤', () {}),
        _buildMenuButton(Icons.flight_takeoff, '休假', () {}),
        _buildMenuButton(Icons.receipt_long, '薪資單', () {}),
      ],
    );
  }

  // 單一功能按鈕的模板
  Widget _buildMenuButton(IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.orange),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
