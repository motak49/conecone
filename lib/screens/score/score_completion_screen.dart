import 'package:flutter/material.dart';
// ▼ 1. インポートを追加（パスは階層に合わせて調整してください）
import 'score_home_screen.dart';


class GolfCompletionScreen extends StatelessWidget {
  const GolfCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 100),
            const SizedBox(height: 24),
            const Text(
              "登録完了！",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "スコアカードのデータが保存されました。",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // 【パターンB】確実に「ゴルフホーム」を新しく開いて戻りたい場合
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const GolfHomeScreen()),
                  (route) => route.isFirst, // または false にして履歴を全消去
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text("ホームへ戻る"),
            ),
          ],
        ),
      ),
    );
  }
}