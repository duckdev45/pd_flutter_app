// lib/announcement_page.dart

import 'package:flutter/material.dart';

// 為了讓程式碼更結構化，我們先定義一個「公告」的資料模型 (Data Model)
class Announcement {
  final String title;
  final String author;
  final DateTime date;
  final String content;
  final IconData icon;

  const Announcement({
    required this.title,
    required this.author,
    required this.date,
    required this.content,
    this.icon = Icons.campaign, // 預設圖示
  });
}

// 這裡是我們的假資料，未來會從 Supabase 取得
final List<Announcement> mockAnnouncements = [
  Announcement(
    title: '磐鼎觀峰寺 開啟廟門科儀儀式',
    author: '管理部',
    date: DateTime(2025, 10, 4),
    // 假設是今天發的公告
    icon: Icons.temple_hindu,
    // 給一個符合情境的圖示
    content:
        '供奉主神觀音佛祖預定國曆10月25日早上8點到倉庫，佛祖選定早上吉時9點15分舉行開啟廟門科儀儀式。\n\n'
        '（ㄧ）早上科儀活動項目有：\n'
        '1、07:50請神\n'
        '2、慶成謝土\n'
        '3、鍾馗開廟門\n'
        '4、六興宮中壇元帥壓煞\n'
        '5、入火安座\n\n'
        '（二）於18:00舉辦慶成福宴及煙火，當日所有工地會全休，有請家人參加福宴人數，請報名，利於統計宴席桌次',
  ),
  // 你可以繼續在這裡加上更多假公告
  Announcement(
    title: '員工通知',
    author: '人資部',
    date: DateTime(2025, 10, 2),
    icon: Icons.health_and_safety,
    content: '各位同仁好，年度員工健康檢查將於下週三舉行，請...',
  ),
];

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // 使用 ListView.builder 來顯示公告列表，效能最好
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: mockAnnouncements.length, // 列表的項目數量
        itemBuilder: (context, index) {
          // 根據 index 取得對應的公告
          final announcement = mockAnnouncements[index];
          // 回傳一個卡片樣式的 Widget
          return _buildAnnouncementCard(context, announcement);
        },
      ),
    );
  }

  // 單張公告卡片的模板
  Widget _buildAnnouncementCard(
    BuildContext context,
    Announcement announcement,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片 Header: 圖示、發布者、日期
            Row(
              children: [
                Icon(announcement.icon, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Text(
                  announcement.author,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(), // Spacer 會自動填滿中間的空間，把日期推到最右邊
                Text(
                  // 把日期格式化成 'yyyy-MM-dd'
                  '${announcement.date.year}-${announcement.date.month.toString().padLeft(2, '0')}-${announcement.date.day.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 30),

            // 公告標題
            Text(
              announcement.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.4, // 行高
              ),
            ),
            const SizedBox(height: 16),

            // 公告內文 (用 RichText 來做更細緻的排版)
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.8, // 增加行高讓長文更好讀
                  fontFamily: 'NotoSansTC', // 確保這裡的字體設定和 App 主題一致
                ),
                children: _parseContent(announcement.content), // 解析內文
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 解析內文，讓有編號的項目自動加上粗體和縮排
  List<TextSpan> _parseContent(String content) {
    final List<TextSpan> spans = [];
    final lines = content.split('\n'); // 用換行符號切開每一行

    for (var line in lines) {
      // 檢查是否是我們的清單項目
      if (line.startsWith('（ㄧ）') ||
          line.startsWith('（二）') ||
          RegExp(r'^\d+、').hasMatch(line)) {
        spans.add(
          TextSpan(
            text: '  $line\n', // 加上一點縮排
            style: const TextStyle(fontWeight: FontWeight.bold), // 讓清單項目變粗體
          ),
        );
      } else {
        spans.add(TextSpan(text: '$line\n'));
      }
    }
    return spans;
  }
}
