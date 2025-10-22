import 'package:flutter/material.dart';
import 'home_page.dart';
import 'registration_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://imebwrgaathiltkwjbut.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltZWJ3cmdhYXRoaWx0a3dqYnV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwODcwMjksImV4cCI6MjA3NjY2MzAyOX0.krvxM1GdH8e7X21UEY8umWxeqXAohz8tCLlcknZxK-s',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryAccentColor = Color(0xFFF7AE34);
    final ThemeData customTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansTC',
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccentColor,
        primary: primaryAccentColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withAlpha(200),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 25.0,
        ),
        prefixIconColor: Colors.grey[600],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: primaryAccentColor, width: 2.0),
        ),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );

    return MaterialApp(
      title: '胖丁營造', // <-- 名字改一下比較有 FU
      theme: customTheme,
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ✨ [魔改點 1] LoginPage
// 已經是 StatefulWidget
// 了，太好了！

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ✨ [魔改點 2] 加上 Controller
  // 跟
  // state
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ✨ [魔改點 3] 把註冊頁的 helper functions
  // 搬
  // 過來
  Future<String?> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }
    return null;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('手機號碼和密碼不可為空');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();
      final dummyEmail = '$phone@example.com';
      final currentDeviceId = await _getDeviceId();

      if (currentDeviceId == null) {
        throw Exception('無法讀取裝置 ID');
      }

      // Step 1: 驗證身份
      final authResponse = await supabase.auth.signInWithPassword(
        email: dummyEmail,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('登入失敗，請稍後再試');
      }

      // Step 2: 驗證裝置
      final deviceResponse = await supabase
          .from('devices')
          .select('device_id')
          .eq('user_id', user.id)
          .single();

      final boundDeviceId = deviceResponse['device_id'] as String?;

      // Step 3: 比對裝置 ID
      if (boundDeviceId == null || boundDeviceId != currentDeviceId) {
        await supabase.auth.signOut(); // 強制登出
        throw Exception('登入失敗：此帳號已綁定於其他裝置');
      }

      // Step 4: 雙重驗證 Pass！
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      _showErrorSnackBar('登入錯誤: ${e.message}');
    } on PostgrestException catch (e) {
      _showErrorSnackBar('登入錯誤: 找不到裝置綁定紀錄 (Code: ${e.code})');
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final Color primaryAccentColor = Theme.of(context).colorScheme.primary;

    // [保留] 你的 UI 結構完全不用動
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/construction_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.9),
            ), // <-- 這裡你用 withValues 怪怪的，我改 opacity
          ),
          SingleChildScrollView(
            child: SizedBox(
              height: screenHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 5),
                  Image.asset('assets/images/main.png', height: 150),
                  const SizedBox(height: 10),
                  const Text(
                    '胖丁營造',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '出勤系統',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50.0),
                    child: Column(
                      children: [
                        // ✨ [魔改點 5] 綁定 Controller
                        TextField(
                          controller: _phoneController, // <--- 綁定
                          decoration: InputDecoration(
                            hintText: '手機號碼',
                            prefixIcon: const Icon(Icons.phone_iphone_rounded),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 50,
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 20), // <-- 你原本這邊沒有密碼欄
                        // ✨ [魔改點 6] 加上密碼欄 & 綁定 Controller
                        TextField(
                          controller: _passwordController, // <--- 綁定
                          obscureText: true, // <--- 隱藏密碼
                          decoration: InputDecoration(
                            hintText: '密碼',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 50,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 30),

                        // ✨ [魔改點 7] 登入按鈕綁定 function 跟 Loading 狀態
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          // <--- 綁定
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryAccentColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          child:
                              _isLoading // <--- 加上 Loading 效果
                              ? const SizedBox(
                                  // 用 SizedBox 限定大小
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text('登入'),
                        ),

                        const SizedBox(height: 20),
                        // [保留] 你的註冊按鈕
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  // 登入時不給按
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegistrationPage(),
                                    ),
                                  );
                                },
                          child: const Text(
                            '註冊帳號',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
