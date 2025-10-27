import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'home_page.dart';

// 方便 call Supabase
final supabase = Supabase.instance.client;

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _bindEquipment = true; // 預設打勾，你原本是 false

  // 用來存使用者輸入的資料
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _isLoading = false;

  // 取得裝置 ID 的 function (你的 code 裡沒有，我補上)
  Future<String?> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor; // iOS 推薦用這個
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Android 用這個
    }
    return null;
  }

  // 顯示錯誤訊息的 SnackBar (你的 code 裡沒有，我補上)
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // 註冊按鈕的真實邏輯
  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // 驗證沒過，閃人
    }
    if (!_bindEquipment) {
      _showErrorSnackBar('必須同意綁定手機裝置碼才能註冊');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: 取得裝置 ID
      final deviceId = await _getDeviceId();
      if (deviceId == null) {
        throw Exception('無法取得裝置 ID');
      }

      // ✨ [魔改點 1] 這就是 The Fix！
      final phone = _phoneController.text.trim();
      // 我們在手機號後面加上一個假網域，騙過 Supabase 的 Email 驗證
      final dummyEmail = '$phone@example.com';

      // Step 2: 註冊帳號
      final authResponse = await supabase.auth.signUp(
        email: dummyEmail, // <--- ✨ [修改] 傳入假 Email
        password: _passwordController.text.trim(),
        data: {
          'full_name': _nameController.text.trim(),
          'nickname': _nicknameController.text.trim(), // <--- ✨ [新增] 存入暱稱
          'phone': phone, // <--- 順便把真的手機號也存起來
        },
      );

      if (authResponse.user == null) {
        throw Exception('註冊失敗，請稍後再試');
      }

      final userId = authResponse.user!.id;

      // Step 3: 綁定裝置 (寫入我們自訂的 devices 表)
      await supabase.from('devices').insert({
        'user_id': userId,
        'device_id': deviceId,
      });

      // Step 4: 註冊成功，直接跳轉到主頁
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false, // 移除所有舊頁面
        );
      }
    } on AuthException catch (e) {
      _showErrorSnackBar('註冊錯誤: ${e.message}');
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        _showErrorSnackBar('註冊失敗：此裝置或手機號碼已被綁定');
      } else {
        _showErrorSnackBar('資料庫錯誤: ${e.message}');
      }
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        // 這行在 Client 端跑可能會沒權限，但先留著
        // await supabase.auth.admin.deleteUser(currentUser.id);
      }
    } catch (e) {
      _showErrorSnackBar('發生未知錯誤: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 從 home_page.dart 借來的配色
  static const Color pageBackground = Color(0xFFF9F6F1);
  static const Color accentOrange = Color(0xFFF7AE34);
  static const Color darkGrayText = Color(0xFF59534C);
  static const Color lightGrayText = Color(0xFF867F78);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkGrayText),
        title: const Text(
          '建立新帳號',
          style: TextStyle(color: darkGrayText, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextFormField(
                  controller: _phoneController,
                  label: '手機號碼',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _passwordController, // <--- ✨ [新增] 密碼欄位
                  label: '密碼',
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                _buildTextFormField(controller: _nameController, label: '姓名'),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _nicknameController, // <--- ✨ [新增] 暱稱欄位
                  label: '暱稱',
                ),
                const SizedBox(height: 24),
                _buildCheckbox(),
                const SizedBox(height: 10),
                _buildRegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: lightGrayText),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentOrange, width: 2),
        ),
      ),
      style: const TextStyle(color: darkGrayText, fontWeight: FontWeight.w500),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '此欄位不可為空';
        }
        return null;
      },
    );
  }

  Widget _buildCheckbox() {
    return CheckboxListTile(
      title: const Text(
        '綁定手機裝置碼',
        style: TextStyle(color: darkGrayText, fontWeight: FontWeight.w500),
      ),
      value: _bindEquipment,
      onChanged: (bool? value) {
        setState(() {
          _bindEquipment = value ?? false;
        });
      },
      activeColor: accentOrange,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleRegister,
      style: ElevatedButton.styleFrom(
        backgroundColor: accentOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
          : const Text('註冊'),
    );
  }
}
