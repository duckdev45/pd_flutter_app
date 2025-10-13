import 'package:flutter/material.dart';
// 假設你的 home_page.dart 存在，先放著
// import 'home_page.dart';

// --- (我是分隔線) ---
// 為了方便導航，我先做一個假的 HomePage，這樣按下登入鈕才不會報錯
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('打卡 App 主頁')),
      body: const Center(child: Text('恭喜你，成功登入啦！🎉')),
    );
  }
}
// --- (以上是假頁面，你可以換成你自己的) ---


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✨ [魔改點 1] 定義你的專屬色票！
    // 把 #9B6E23 轉成 Flutter 的 Color 物件，以後要換色從這裡改就好，方便管理
    const Color customOrange = Color(0xFF9B6E23);
    const Color lightGrey = Color(0xFFF5F5F5); // 比 Colors.grey[200] 再細緻一點的灰

    // ✨ [魔改點 2] 整個 App 的主題設定，注入你的橘色靈魂
    final ThemeData customTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansTC', // 這個字體選得好，繼續用
      scaffoldBackgroundColor: lightGrey, // 使用我們定義的淺灰色當背景
      colorScheme: ColorScheme.fromSeed(
        seedColor: customOrange,
        primary: customOrange, // 主要色系，按鈕、焦點顏色都會吃到
        background: lightGrey, // 定義一下背景色
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 25.0,
        ),
        prefixIconColor: Colors.grey[600],
        // ✨ [魔改點 3] 讓輸入框的邊框風格更統一
        // 拿掉原本 TextField 裡面的 enabledBorder, focusedBorder
        // 直接在 Theme 裡統一設定，這樣所有 TextField 都長一樣，超乾淨
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: customOrange, width: 2.0),
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

class CustomBackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height * 0.9);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.8, size.width, size.height * 0.9);
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
    final screenHeight = MediaQuery.of(context).size.height;
    // 直接從 Theme 拿我們定義好的顏色，方便又不會出錯
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 上半部：背景 + Header
            SizedBox(
              height: screenHeight * 0.45, // 稍微調低一點，讓表單空間多一些
              child: ClipPath(
                clipper: CustomBackgroundClipper(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  color: primaryColor, // ✨ [魔改點 4] 直接使用我們的主題橘色，告別漸層
                  child: Stack(
                    children: [
                      // Logo 置中
                      Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/pd_logo_dark.png', // 記得要在 pubspec.yaml 設定這個 asset 喔！
                          height: 150,
                        ),
                      ),
                      // 標題靠右下
                      const Align(
                        alignment: Alignment(0.9, 0.6), // 稍微往上跟左邊挪一點
                        child: Text(
                          '磐鼎營造',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // 在深色背景上，用白色字更突出
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20), // 給上面和表單之間一點呼吸空間

            // 下半部：表單
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  // ✨ [魔改點 5] 簡化 TextField，因為樣式都交給 Theme 去管了
                  const TextField(
                    decoration: InputDecoration(
                      hintText: '手機號碼', // 改成手機號碼比較符合我們之前的討論
                      prefixIcon: Icon(Icons.phone_iphone_rounded),
                    ),
                    keyboardType: TextInputType.phone, // 鍵盤直接跳數字，貼心！
                  ),
                  const SizedBox(height: 20),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '密碼',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ✨ [魔改點 6] 登入按鈕，樣式也從 Theme 繼承
                  ElevatedButton(
                    onPressed: () {
                      // 這裡未來會放你的 Supabase 登入驗證
                      // 現在我們先假設只要按下按鈕，就代表登入成功
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // 吃主題色
                      foregroundColor: Colors.white, // 文字用白色
                      minimumSize: const Size(double.infinity, 55), // 滿寬按鈕
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2, // 加一點字距，更有 feel
                      ),
                    ),
                    child: const Text('登入'),
                  ),

                  // ✨ [魔改點 7] 加上註冊按鈕的入口，讓 UI Flow 更完整
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      // 這裡可以導航到你的註冊頁面
                      print('跳轉到註冊頁面！');
                    },
                    child: Text(
                      '還沒有帳號？點此註冊',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
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