import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✨ [魔改點 1] 配色調整：
    // 在有背景圖的情況下，原本的 #9B6E23 可能會被背景吃掉。
    // 我們選一個亮度更高、稍微帶點土色或更深的橘色，
    // 或是為了讓前景突出，直接使用一個能與背景圖形成良好對比的顏色。
    // 這裡我嘗試使用一個更飽和、略深的橘紅，在工地背景下會更顯眼，
    // 並且給它一點點的透明度，讓背景若隱若現。
    // 如果想要圖一那種比較內斂的風格，也可以考慮用深藍色或深灰色來搭配。
    const Color primaryAccentColor = Color(0xFFB85C1A); // 調整後的主題色
    const Color darkerOverlay = Colors.black45; // 用於背景圖上的深色覆蓋

    final ThemeData customTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansTC',
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccentColor,
        primary: primaryAccentColor,
        // 背景色不再是單純的淺灰，交給 ImageBackground 處理
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withAlpha(200),
        // 輸入框內部略微透明，有一點點穿透感
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 25.0,
        ),
        prefixIconColor: Colors.grey[600],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none, // 無邊框設計，更接近圖一
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none, // 無邊框設計
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
            color: primaryAccentColor,
            width: 2.0,
          ), // 聚焦時有邊框
        ),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0, // 無陰影
        iconTheme: IconThemeData(color: Colors.white), // 返回箭頭設為白色
      ),
    );

    return MaterialApp(
      title: 'XX營造',
      theme: customTheme,
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final Color primaryAccentColor = Theme.of(context).colorScheme.primary;

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
            child: Container(color: Colors.grey.withValues(alpha: 1)),
          ),

          // 3. UI 內容 (Logo, 表單)，置中顯示
          SingleChildScrollView(
            // 保持可滾動，避免鍵盤彈出時內容溢出
            child: SizedBox(
              height: screenHeight, // 讓 SingleChildScrollView 撐滿高度
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 垂直置中
                children: [
                  const Spacer(flex: 5), // 上方留白，讓 Logo 偏上
                  Image.asset('assets/images/main.png', height: 150),
                  const SizedBox(height: 10),
                  // App Title
                  const Text(
                    '胖丁營造',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // 白色字在深色背景上更清楚
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Slogan 或副標題 (參考圖一的 "Create late hour...")
                  const Text(
                    '出勤系統',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70, // 稍微半透明的白色
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20), // Logo 和表單之間留白
                  // 表單區塊
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50.0),
                    // 左右邊距拉大
                    child: Column(
                      children: [
                        // 輸入框
                        TextField(
                          decoration: InputDecoration(
                            hintText: '手機號碼',
                            prefixIcon: const Icon(Icons.phone_iphone_rounded),
                            // ✨ [魔改點 5] 圖一的輸入框左邊有返回箭頭，這裡我們可以加一個
                            // 或者簡化，只保留 Phone 圖標
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 50,
                            ),
                            // 如果你想要圖一那樣的透明輸入框，可以調整 fillColor 和 borderSide
                          ),
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: Colors.black87,
                          ), // 輸入文字顏色
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          obscureText: true,
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

                        // 登入按鈕
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryAccentColor,
                            // 使用調整後的主題色
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
                          child: const Text('登入'),
                        ),

                        const SizedBox(height: 20),
                        // 註冊連結
                        TextButton(
                          onPressed: () {
                            print('跳轉到註冊頁面！');
                          },
                          child: const Text(
                            '還沒有帳號？點此註冊',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ), // 在深色背景上用白色
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3), // 下方留白，讓整體置中
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
