import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData customTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansTC',
      // 繼續使用這個字體讓中文更好看
      scaffoldBackgroundColor: Colors.grey[200],
      // 這次背景用淺灰色，更能凸顯白色卡片
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange,
        primary: Colors.orange,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: Colors.orange, width: 2.0),
        ),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
    );

    return MaterialApp(
      title: '磐鼎營造',
      theme: customTheme,
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 這是我們用來裁切背景形狀的工具
class CustomBackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(0, size.height, 80, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      // 這次不用 Stack，我們直接把背景放在 body
      // 這樣可以避免鍵盤彈出時影響到背景形狀
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 上半部：漸層背景 + Header
            SizedBox(
              height: screenHeight * 0.5, // 佔螢幕一半
              child: ClipPath(
                // 使用 ClipPath 來裁剪子元件
                clipper: CustomBackgroundClipper(), // 使用我們自定義的 Clipper
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 40,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepOrange, Colors.yellow], // 橘黃漸層
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  // 用 Stack 來排版 Logo 和標題
                  child: Stack(
                    children: [
                      // Logo 置中
                      Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/pd_logo.png',
                          height: 150,
                        ),
                      ),
                      // 標題靠右下
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          '磐鼎營造',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withAlpha(200), // 0.9*255 ≈ 230
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 下半部：表單
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: '帳號',
                      prefixIcon: Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                      // 加一點陰影更有立體感
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(
                          color: Colors.orange,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '密碼',
                      prefixIcon: Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white,
                      // 加一點陰影更有立體感
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(
                          color: Colors.orange,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 登入按鈕
                  ElevatedButton(
                    onPressed: () {
                      // 這裡未來會放你的 Supabase 登入驗證
                      // 現在我們先假設只要按下按鈕，就代表登入成功

                      // 導航到 HomePage
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage()),
                      );
                    }, style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    // 滿寬按鈕
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                    child: const Text('登入'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
