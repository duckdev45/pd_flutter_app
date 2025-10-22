import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // 導入中文日期符號
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

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
  String _formattedDate = '';
  String _dayOfWeek = '';
  String _formattedTime = '';
  Timer? _timer;

  String _nickname = '...'; // <--- 暱稱

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('zh_TW', null).then((_) {
      _updateTime(); // 立即更新一次
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _updateTime();
      });
    });

    _loadUserData(); // <--- ✨ [新增] 頁面一打開，就去抓使用者資料
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

  // <--- ✨ [新增] 抓取暱稱的 Function ---
  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // user.userMetadata
      // 就是我們在 signUp
      // 時塞 data: {}
      // 的地方
      final userNickname = user.userMetadata?['nickname'] as String?;
      final userFullName = user.userMetadata?['full_name'] as String?;

      setState(() {
        // 如果有暱稱，就用暱稱；沒有就用姓名；再沒有就用 'User'
        _nickname = userNickname ?? userFullName ?? 'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✨ [魔改點 1] 注入靈魂！這才是我們要的配色！
    const Color pageBackgroundColor = Color(0xFFF8F8F8);
    // 婚禮 App 色系
    const Color accentOrange = Color(0xFFF7AE34); // 婚禮橘 (CTA色)
    const Color darkGrayText = Color(0xFF59534C); // 婚禮深灰 (標題)
    const Color lightGrayText = Color(0xFF867F78); // 婚禮淺灰 (內文)

    // ✨ [魔改點 2] 關鍵！把背景色改掉！
    // 不再用快看不到的 #F9F6F1
    const Color mainContentColorDark = Color(0xFF6D635B); // 改為沉穩的暖灰色
    const Color mainContentColorLight = Color(0xFFF9F6F1); // <-- 奶油米色

    return Scaffold(
      body: Container(
        color: mainContentColorLight, // 確保整個背景都是奶油米色
        child: SafeArea(
          bottom: false, // 停用底部的安全區域邊距
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. 頂部文字區塊 ---
              _buildHeader(
                accentOrange: accentOrange,
                darkGrayText: darkGrayText,
                lightGrayText: lightGrayText,
                nickname: _nickname, // <--- 修正，傳入正確暱稱
              ),

              // --- 2. 主內容區塊 ---
              Expanded(
                child: LayoutBuilder(
                  // 直接使用 LayoutBuilder，移除多餘的 Stack
                  builder: (context, constraints) {
                    final double screenHeight = constraints.maxHeight;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // --- ✨ [魔改點 3] 深色底 -> 燕麥色 ---
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: screenHeight,
                          child: ClipPath(
                            clipper: MainArcClipper(),
                            child: Container(
                              color: mainContentColorDark,
                            ), // <-- 套用燕麥色
                          ),
                        ),

                        // --- ✨ [魔改點 4] 淺色疊加 -> 奶油米色 ---
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: screenHeight * 0.9,
                          child: ClipPath(
                            clipper: OverlayArcClipper(),
                            child: Container(
                              // 套用奶油米色 + 你原本的透明度
                              color: mainContentColorLight.withAlpha(200),
                            ),
                          ),
                        ),

                        // --- [保留] 打卡地點 (文字換色) ---
                        Positioned(
                          top: screenHeight * 0.12,
                          left: 0,
                          right: 0,
                          child: _buildWorksiteInfo(Colors.white), // <-- 改為白色
                        ),

                        // --- [保留] 打卡按鈕 (大改造) ---
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 50.0),
                            child: _buildClockInButton(
                              accentOrange,
                            ), // <-- 傳入婚禮橘
                          ),
                        ),

                        // --- [保留] 上下班時間 (文字換色) ---
                        Positioned(
                          bottom: screenHeight * 0.18,
                          left: 0,
                          right: 0,
                          child: _buildClockTimes(Colors.white, Colors.white70),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ [保留] Header 大改造，注入配色
  Widget _buildHeader({
    required Color accentOrange,
    required Color darkGrayText,
    required Color lightGrayText,
    required String nickname, // <--- ✨ [修改] 接收暱稱
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32.0, 64.0, 32.0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_formattedDate (${_dayOfWeek.isEmpty ? "" : _dayOfWeek})',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: lightGrayText, // <-- 使用淺灰
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formattedTime.isEmpty ? "--:--" : _formattedTime,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: darkGrayText, // <-- 使用深灰
                ),
              ),
            ],
          ),
          const Spacer(),
          // --- 換回膠囊按鈕，才 high-vibe！ ---
          // --- Hi,duck! 文字無背景、主色、波浪線 ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $nickname', // <--- 顯示暱稱
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: mainContentColorDark,
                  ),
                ),
                _HandDrawnWaveLine(
                  color: mainContentColorDark,
                  width: 120,
                  height: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✨ [保留] 按鈕大簡化！回歸初心！
  Widget _buildClockInButton(Color accentOrange) {
    const double outerSize = 200;
    const double innerSize = 170;
    return Container(
      width: outerSize,
      height: outerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: accentOrange, width: 8),
        boxShadow: [
          BoxShadow(
            color: accentOrange.withOpacity(0.25),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF3E0), // 更淺的奶油米色
            border: Border.all(color: Color(0xFFE0C9A6), width: 2), // 更淺的咖啡色
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              print('打卡按鈕被按下了！');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentOrange,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 8,
              shadowColor: accentOrange.withOpacity(0.18),
              padding: const EdgeInsets.all(20),
              textStyle: const TextStyle(
                fontFamily: 'NotoSansiTC',
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

  // ✨ [保留] 打卡地點 (文字換色)
  Widget _buildWorksiteInfo(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📍', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Text(
          '胖丁營造倉庫',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textColor, // <-- 使用傳入的顏色
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ✨ [保留] 上下班時間 (文字換色)
  Widget _buildClockTimes(Color primaryTextColor, Color secondaryTextColor) {
    const String clockInTime = '07:58';
    const String clockOutTime = '--:--';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeColumn(
          '上班時間',
          clockInTime,
          primaryTextColor,
          secondaryTextColor,
        ),
        Container(
          height: 80,
          width: 3,
          color: Colors.grey,
          margin: const EdgeInsets.symmetric(horizontal: 32.0),
        ),
        _buildTimeColumn(
          '下班時間',
          clockOutTime,
          primaryTextColor,
          secondaryTextColor,
        ),
      ],
    );
  }

  // 輔助 Widget (也要吃顏色)
  static const Color mainContentColorDark = Color(0xFF6D635B);

  Widget _buildTimeColumn(
    String title,
    String time,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            color: mainContentColorDark, // <-- 換成傳入的次要顏色
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: mainContentColorDark, // <-- 使用 mainContentColorDark
          ),
        ),
      ],
    );
  }
}

// --- 手繪風波浪線 Widget ---
class _HandDrawnWaveLine extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const _HandDrawnWaveLine({
    required this.color,
    this.width = 100,
    this.height = 12,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _HandDrawnWavePainter(color: color)),
    );
  }
}

class _HandDrawnWavePainter extends CustomPainter {
  final Color color;

  _HandDrawnWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    // 手繪感波浪（不規則）
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.18,
      size.height * 0.2,
      size.width * 0.32,
      size.height * 1.2,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.cubicTo(
      size.width * 0.68,
      size.height * 0.2,
      size.width * 0.82,
      size.height * 1.2,
      size.width,
      size.height * 0.7,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
