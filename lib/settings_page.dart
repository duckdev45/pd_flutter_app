// lib/settings_page.dart
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('這裡是設定頁面', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}