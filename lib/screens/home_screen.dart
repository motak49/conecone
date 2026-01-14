import 'package:flutter/material.dart';
import 'score/score_home_screen.dart'; // 麻雀の画面をインポート
import 'myclub/myclub_home_screen.dart'; // ゴルフの画面をインポート
import 'dart:ui';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ユーザー名（仮）
    const String userName = "コネコネ 1号（右利き）";

    return Scaffold(
      // ★重要: AppBarの裏までbody（背景画像）を拡張する設定
      //extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text('コネコネ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2.0, color: Colors.white)), // 文字色を明示的に白に
        centerTitle: true,
        backgroundColor: Colors.transparent, // 透明のまま
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // 戻るボタン等の色
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 32, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('会員機能は準備中です')),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),

      // 背景色は削除し、body内で画像を配置します
      // backgroundColor: const Color(0xFF121212), 

      body: Stack(
        children: [
          // 1. 背景画像レイヤー
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                // ★ここで画像を指定 (pubspec.yamlの設定に合わせてパスを調整してください)
                image: AssetImage('assets/images/home_bg.png'), 
                fit: BoxFit.cover, // 画面いっぱいに画像を広げる
              ),
            ),
          ),
          
          // 2. 黒い半透明レイヤー（画像の視認性を上げるため：任意）
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // 3. コンテンツレイヤー (元のPadding以下の内容)
          // SafeAreaで囲むことで、AppBarやステータスバーと被るのを防ぎます
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    "- 開発中のもの一覧 -",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // メニューパネルのグリッド表示
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        // 【変更】_buildMenuCard(...) ではなく MenuCard(...) を使います
                        MenuCard(
                          title: 'マイクラブ',
                          icon: Icons.sports_golf,
                          color: Colors.blueGrey.shade300,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyClubHomeScreen()),
                            );
                          },
                        ),
                        MenuCard(
                          title: 'スコア登録',
                          icon: Icons.golf_course,
                          color: Colors.blueGrey.shade800,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const GolfHomeScreen()),
                            );
                          },
                        ),
                        MenuCard(
                          title: 'テスト中',
                          icon: Icons.casino,
                          color: Colors.purple.shade900,
                          onTap: () => _showComingSoon(context),
                        ),
                        MenuCard(
                          title: 'テスト中',
                          icon: Icons.phishing,
                          color: Colors.blue.shade900,
                          onTap: () => _showComingSoon(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        // 【修正1】ぼかしを「2.0」まで下げる（以前は10.0）
        // ※完全にくっきり見せたい場合は、ここを 0.0 にしてください
        filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
        child: Container(
          decoration: BoxDecoration(
            // 【修正2】背景の透け感を調整
            // alpha: 0.3 〜 0.4 くらいが「背景が見える」かつ「文字が読める」バランスです
            color: color.withValues(alpha: 0.4), 
            
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              // 枠線を少し強調して、ボタンの存在感を出します
              color: Colors.white.withValues(alpha: 0.5), 
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                // グラデーションも透明度を上げて、よりクリアにします
                Colors.white.withValues(alpha: 0.15), 
                Colors.white.withValues(alpha: 0.05), 
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: color.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon, 
                    size: 48, 
                    color: Colors.white,
                    shadows: const [
                      // アイコンの影を強くして、背景が派手でも浮き立たせる
                      Shadow(blurRadius: 12, color: Colors.black54, offset: Offset(2, 2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        // 文字の影もしっかりつけて可読性を確保
                        Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('この機能は開発中です 🚧'), duration: Duration(milliseconds: 800)),
    );
  }
}

// ★ファイルの末尾に追加してください
class MenuCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  bool _isHovered = false; // マウスが乗っているかどうかのフラグ

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // マウス検知
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click, // カーソルを手の形にする
      
      // ぼかしのアニメーション (TweenAnimationBuilder)
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200), // アニメーション時間
        tween: Tween<double>(
          begin: 2.0, 
          end: _isHovered ? 10.0 : 2.0, // ホバー時は10(曇り)、通常は2(クリア)
        ),
        builder: (context, sigma, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  // ホバー時は色を少し濃く(0.6)、通常は薄く(0.4)
                  color: widget.color.withValues(alpha: _isHovered ? 0.6 : 0.4),
                  
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    // ホバー時は枠線を白く強調、通常は半透明
                    color: _isHovered 
                        ? Colors.white.withValues(alpha: 0.9) 
                        : Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      // ホバー時はハイライトを強く
                      Colors.white.withValues(alpha: _isHovered ? 0.3 : 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    splashColor: widget.color.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // アイコンのアニメーション（少し拡大させても面白いですが、今回は色のみ）
                        Icon(
                          widget.icon,
                          size: 48,
                          color: _isHovered ? Colors.white : Colors.white.withValues(alpha: 0.9),
                          shadows: [
                            Shadow(
                              blurRadius: _isHovered ? 20 : 12, // ホバー時は発光を強く
                              color: _isHovered ? Colors.cyanAccent : Colors.black54,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            shadows: const [
                              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}