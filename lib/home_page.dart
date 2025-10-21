import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // 導入中文日期符號
import 'dart:async';

// --- (我是分隔線) ---
// ✨ [保留] 你的 Clipper 寫的超棒！
class MainArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 80);
    path.quadraticBezierTo(size.width / 2, 20, size.width, 80);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ✨ [保留] 你的第 2 個 Clipper 也超棒！
class OverlayArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 100);
    path.quadraticBezierTo(size.width / 2, 40, size.width, 100);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
// --- (Clipper 結束) ---

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- (你的 initState, dispose, _updateTime - 完全不用動) ---
  String _formattedDate = '';
  String _dayOfWeek = '';
  String _formattedTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('zh_TW', null).then((_) {
      _updateTime();
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _updateTime();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _formattedDate = DateFormat('yyyy-MM-dd').format(now);
      _dayOfWeek = DateFormat('E', 'zh_TW').format(now);
      _formattedTime = DateFormat('HH:mm').format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBackgroundColor = Color(0xFFF8F8F8);
    const Color mainContentColorDark = Color(0xFF36B37E);
    const Color mainContentColorLight = Color(0xFF6DC8A3);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. 頂部文字區塊 ---
            _buildHeader(), // ✨ [保留] 你的 Header 寫得很好
            // --- 2. 綠色主內容區塊 ---
            Expanded(
              child: LayoutBuilder(
                // ✨ [保留] 你的 LayoutBuilder 結構是正確的！
                builder: (context, constraints) {
                  final double screenHeight = constraints.maxHeight;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // --- 深綠色 (底下) ---
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: screenHeight,
                        child: ClipPath(
                          clipper: MainArcClipper(),
                          child: Container(color: mainContentColorDark),
                        ),
                      ),
                      // --- 淺綠色 (疊在上面) ---
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: screenHeight * 0.9,
                        child: ClipPath(
                          clipper: OverlayArcClipper(),
                          child: Container(
                            color: mainContentColorLight.withAlpha(200),
                          ),
                        ),
                      ),

                      // --- ✨ [魔改點 1] 新增：打卡地點 ---
                      Positioned(
                        top: screenHeight * 0.12, // 靠感覺抓個大概 18% 的高度
                        left: 0,
                        right: 0,
                        child: _buildWorksiteInfo(),
                      ),

                      // --- 打卡按鈕 (中間) ---
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 50.0),
                          child: _buildClockInButton(mainContentColorDark),
                        ),
                      ),
                      // --- ✨ [魔改點 2] 新增：上下班時間 ---
                      Positioned(
                        bottom: screenHeight * 0.2, // 離底部 10% 的高度
                        left: 0,
                        right: 0,
                        child: _buildClockTimes(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ [保留] 你的 Header 寫得超讚
  Widget _buildHeader() {
    const Color mainContentColorDark = Color(0xFF36B37E);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32.0, 32.0, 32.0, 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_formattedDate (${_dayOfWeek.isEmpty ? "" : _dayOfWeek})',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                _formattedTime.isEmpty ? "--:--" : _formattedTime,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: mainContentColorDark,
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: const Text(
              'Hi,duck!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ✨ [保留] 你的 Button 也很讚 ---
  Widget _buildClockInButton(Color primaryColor) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: primaryColor.withOpacity(0.5), width: 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 0,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFB2F5D6), // 更淺的綠色
          ),
          child: ElevatedButton(
            onPressed: () {
              print('打卡按鈕被按下了！');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              shape: const CircleBorder(),
              elevation: 0,
              padding: const EdgeInsets.all(20),
              textStyle: const TextStyle(
                fontFamily: 'NotoSansTC',
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            child: const Text('打卡'),
          ),
        ),
      ),
    );
  }

  // --- ✨ [魔改點 3] 新增：打卡地點 Widget ---
  Widget _buildWorksiteInfo() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('📍', style: TextStyle(fontSize: 26)),
        SizedBox(width: 10),
        Text(
          '胖丁營造倉庫', // TODO: 之後換成變數
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // --- ✨ [魔改點 4] 新增：上下班時間 Widget ---
  Widget _buildClockTimes() {
    const String clockInTime = '07:58';
    const String clockOutTime = '17:02';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeColumn('上班時間', clockInTime),
        Container(
          height: 80,
          width: 2,
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 32.0),
        ),
        _buildTimeColumn('下班時間', clockOutTime),
      ],
    );
  }

  // _buildClockTimes 的輔助 Widget
  Widget _buildTimeColumn(String title, String time) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 22, color: Colors.white, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
