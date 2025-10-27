import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // 導入中文日期符號
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

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

  // --- ✨ [新增] 打卡邏輯需要的 State ---
  Position? _currentPosition; // <--- GPS 位置
  String? _nearestWorksiteName; // <--- 最近案場名稱
  int? _nearestWorksiteId; // <--- 最近案場 ID
  String _clockInTime = '--:--'; // <--- UI 顯示的上班時間
  String _clockOutTime = '--:--'; // <--- UI 顯示的下班時間
  Map<String, dynamic>? _todaysAttendance; // <--- 今天打卡紀錄

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('zh_TW', null).then((_) {
      _updateTime(); // 立即更新一次
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _updateTime();
      });
    });

    _loadUserData(); // <--- ✨ [保留] 頁面一打開，就去抓使用者資料
    _initializeHomePage(); // <--- ✨ [新增] 整合後的初始化 Function
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

  // --- ✨ [新增] 整合後的初始化 Function ---
  Future<void> _initializeHomePage() async {
    // ✨ [偵錯] 使用 try-catch 包裹整個初始化流程，確保任何一步失敗都不會讓 App 崩潰
    try {
      print("🚀 初始化開始...");
      final bool positionAcquired = await _determinePosition();
      print("✅ 定位結束，是否成功: $positionAcquired");

      // 如果成功取得位置，才繼續找最近的案場
      if (positionAcquired) {
        await _findNearestWorksite();
        print("✅ 尋找案場結束，最近案場 ID: $_nearestWorksiteId");
      }

      // 無論如何都嘗試抓取今天的打卡紀錄
      await _fetchTodaysAttendance();
      print("✅ 抓取今日打卡紀錄結束");
    } catch (e) {
      print("🔥 初始化過程中發生錯誤: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('初始化失敗: $e')));
      }
    }
  }

  // <--- ✨ [修改] 抓取暱稱的 Function ---
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

  // --- ✨ [新增] 1. 取得 GPS 位置 ---
  Future<bool> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. 檢查定位服務是否開啟
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('請開啟定位服務')));
      }
      return false;
    }

    // 2. 檢查並請求權限
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('您已拒絕定位權限，將無法進行打卡')));
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('定位權限已被永久拒絕，請至設定中開啟')));
      }
      return false;
    }

    // 3. 權限都通過了，實際去抓 GPS 位置
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      return true;
    } catch (e) {
      print('無法取得位置: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('無法取得目前位置: $e')));
      }
      return false;
    }
  }

  // --- ✨ [新增] 2. 根據 GPS 計算最近案場 ---
  Future<void> _findNearestWorksite() async {
    if (_currentPosition == null) {
      print(
        "❌ _findNearestWorksite: _currentPosition is null, cannot proceed.",
      );
      return;
    }
    print(
      "🌍 _findNearestWorksite: Current position: lat=${_currentPosition!.latitude}, lon=${_currentPosition!.longitude}",
    );

    try {
      // 1. 從 Supabase 抓取所有案場資料
      final List<Map<String, dynamic>> worksites = await supabase
          .from('work_sites')
          .select()
          .eq('is_active', true);

      if (worksites.isEmpty) {
        print(
          "⚠️ _findNearestWorksite: No active worksites found in database.",
        );
        setState(() {
          _nearestWorksiteName = '無可用案場';
        });
        return;
      }

      print(
        "🏢 _findNearestWorksite: Found ${worksites.length} active worksites.",
      );

      double minDistance = double.infinity;
      Map<String, dynamic>? nearestWorksite;

      // 2. 計算哪個案場最近
      for (var site in worksites) {
        final siteLat = site['latitude'] as double?;
        final siteLng = site['longitude'] as double?;
        // ✨ [新增] 取得案場的有效半徑
        final siteRadius =
            (site['radius_meters'] as num?)?.toDouble() ?? 100.0; // 預設 100 公尺

        if (siteLat != null && siteLng != null) {
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            siteLat,
            siteLng,
          );

          print(
            "📏 _findNearestWorksite: Checking site '${site['name']}' (ID: ${site['id']}). Distance: ${distance.toStringAsFixed(2)}m, Radius: ${siteRadius}m",
          );

          // ✨ [關鍵修正] 只有在距離內，且是目前最近的，才選為目標
          if (distance < siteRadius && distance < minDistance) {
            minDistance = distance;
            nearestWorksite = site;
            print(
              "✅ _findNearestWorksite: New nearest site found: '${site['name']}' at ${distance.toStringAsFixed(2)}m.",
            );
          }
        }
      }

      // 3. 更新 State
      if (nearestWorksite != null) {
        setState(() {
          _nearestWorksiteId = nearestWorksite!['id'] as int?;
          _nearestWorksiteName = nearestWorksite['name'] as String?;
        });
      } else {
        print(
          "❌ _findNearestWorksite: No worksite is within the required radius.",
        );
        setState(() {
          _nearestWorksiteName = '附近沒有案場'; // 給予更明確的提示
        });
      }
    } catch (e) {
      print('🔥 _findNearestWorksite: 抓取案場資料時發生錯誤: $e');
      setState(() {
        _nearestWorksiteName = '案場資料錯誤';
      });
    }
  }

  // --- ✨ [新增] 3. 抓取今天的打卡紀錄 ---
  Future<void> _fetchTodaysAttendance() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final response = await supabase
          .from('daily_attendances')
          .select()
          .eq('user_id', user.id) // ✨ [修正] 確保這裡是 user_id
          .eq('work_date', today)
          .maybeSingle();

      if (!mounted) return; // 確保 Widget 還在畫面上

      setState(() {
        _todaysAttendance = response;
        if (response != null) {
          // 更新 UI 上的時間
          final clockIn = response['clock_in_time'] as String?;
          final clockOut = response['clock_out_time'] as String?;

          _clockInTime = clockIn != null
              ? DateFormat('HH:mm').format(DateTime.parse(clockIn))
              : '--:--';
          _clockOutTime = clockOut != null
              ? DateFormat('HH:mm').format(DateTime.parse(clockOut))
              : '--:--';
        } else {
          // 如果今天還沒有任何紀錄，就都設為 '--:--'
          _clockInTime = '--:--';
          _clockOutTime = '--:--';
        }
      });
    } catch (e) {
      print('查詢今日打卡紀錄時發生錯誤: $e');
      // 可以在這裡加入錯誤提示
    }
  }

  // --- ✨ [新增] 4. 按下打卡按鈕的核心邏輯 ---
  Future<void> _handleClockInTap() async {
    // 1. 防呆：確定有抓到 GPS 跟案場
    // ✨ [偵錯] 加入 print 訊息，釐清是哪個變數為 null
    if (_currentPosition == null || _nearestWorksiteId == null) {
      print(
        'Clock-in failed: _currentPosition is ${_currentPosition == null ? 'null' : 'not null'}',
      );
      print(
        'Clock-in failed: _nearestWorksiteId is ${_nearestWorksiteId == null ? 'null' : 'not null'}',
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('無法確定您的位置或找不到附近案場，請稍後再試。')));
      // ✨ [修改] 不要在這裡重新初始化，避免狀態混亂。
      // 如果需要重試，引導使用者手動刷新或由其他機制觸發。
      // await _initializeHomePage();
      return;
    }

    // 2. 在執行操作前，永遠重新抓一次最新的打卡狀態，避免重複操作
    await _fetchTodaysAttendance();

    final now = DateTime.now();
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 3. 判斷現在是該上班、下班，還是已經打完卡了
    if (_todaysAttendance == null) {
      // --- 狀況 A：今天還沒打過任何卡 -> 執行上班打卡 ---
      await _performClockIn(user.id, now);
    } else {
      final clockInTime = _todaysAttendance!['clock_in_time'] as String?;
      final clockOutTime = _todaysAttendance!['clock_out_time'] as String?;

      if (clockInTime != null && clockOutTime == null) {
        // --- 狀況 B：有上班卡，但沒有下班卡 -> 執行下班打卡 ---
        final clockInDateTime = DateTime.parse(clockInTime);
        final duration = now.difference(clockInDateTime);

        if (duration.inHours < 8) {
          // 工時小於 8 小時，跳出 Dialog 確認
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('確認提早下班'),
              content: Text('目前上班時數未滿 8 小時，確定要打下班卡嗎？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('確定'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await _performClockOut(user.id, now);
          }
        } else {
          // 工時已滿，直接打下班卡
          await _performClockOut(user.id, now);
        }
      } else {
        // --- 狀況 C：上班卡和下班卡都打完了 ---
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('您今天已經完成打卡了！')));
      }
    }

    // 4. 不論執行了什麼操作，最後都再抓一次最新狀態來更新 UI
    await _fetchTodaysAttendance();
  }

  // --- ✨ [新增] 5. 執行上班打卡 (INSERT) ---
  Future<void> _performClockIn(String userId, DateTime now) async {
    try {
      await supabase.from('daily_attendances').insert({
        'user_id': userId,
        'work_date': DateFormat('yyyy-MM-dd').format(now),
        'clock_in_time': now.toIso8601String(),
        'clock_in_site_id': _nearestWorksiteId,
        'clock_in_lat': _currentPosition!.latitude, // 修正: 對應資料庫欄位 clock_in_lat
        'clock_in_lon': _currentPosition!.longitude, // 修正: 對應資料庫欄位 clock_in_lon
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('上班打卡成功！'), backgroundColor: Colors.green),
      );
    } catch (e) {
      print('上班打卡失敗: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上班打卡失敗: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- ✨ [新增] 6. 執行下班打卡 (UPDATE) ---
  Future<void> _performClockOut(String userId, DateTime now) async {
    if (_todaysAttendance == null) return;

    try {
      await supabase
          .from('daily_attendances')
          .update({
            'clock_out_time': now.toIso8601String(),
            'clock_out_site_id': _nearestWorksiteId,
            'clock_out_lat': _currentPosition!.latitude,
            // 修正: 對應資料庫欄位 clock_out_lat
            'clock_out_lon': _currentPosition!.longitude,
            // 修正: 對應資料庫欄位 clock_out_lon
          })
          .eq('id', _todaysAttendance!['id']); // 用 primary key 'id' 來更新

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下班打卡成功！'), backgroundColor: Colors.green),
      );
    } catch (e) {
      print('下班打卡失敗: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下班打卡失敗: $e'), backgroundColor: Colors.red),
      );
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

                        // --- ✨ [修改] 上下班時間 (文字換色 & 綁定 State) ---
                        Positioned(
                          bottom: screenHeight * 0.18,
                          left: 0,
                          right: 0,
                          child: _buildClockTimes(
                            Colors.white,
                            Colors.white70,
                            _clockInTime, // <-- 綁定上班時間
                            _clockOutTime, // <-- 綁定下班時間
                          ),
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
      padding: const EdgeInsets.fromLTRB(24.0, 64.0, 14.0, 0),
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
            onPressed: _handleClockInTap, // <-- ✨ [修改] 綁定打卡邏輯
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

  // ✨ [修改] 打卡地點 (綁定 State)
  Widget _buildWorksiteInfo(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📍', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Text(
          _nearestWorksiteName ?? '定位中...', // <-- 綁定最近案場名稱
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

  // ✨ [修改] 上下班時間 (接收 State)
  Widget _buildClockTimes(
    Color primaryTextColor,
    Color secondaryTextColor,
    String clockInTime,
    String clockOutTime,
  ) {
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
            color: mainContentColorDark, // <-- ✨ [修改] 換成傳入的次要顏色
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: mainContentColorDark, // <-- ✨ [修改] 換成傳入的主要顏色
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
