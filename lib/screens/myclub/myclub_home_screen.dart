import 'package:flutter/material.dart';
import '../../helpers/database_helper.dart';
import 'driver_image_search_screen.dart';
import 'myclub_wood_register_screen.dart';
import 'myclub_history_screen.dart';

class MyClubHomeScreen extends StatefulWidget {
  const MyClubHomeScreen({super.key});

  @override
  State<MyClubHomeScreen> createState() => _MyClubHomeScreenState();
}

class _MyClubHomeScreenState extends State<MyClubHomeScreen> {
  Map<String, List<Map<String, dynamic>>> _clubData = {};

  @override
  void initState() {
    super.initState();
    _fetchClubData();
  }

  Future<void> _fetchClubData() async {
    // ダミーデータ（実際はDBから取得）
    final List<Map<String, dynamic>> dummyClubs = [
      {'category': 'Wood', 'number': '1W', 'model_name': 'Taylormade M1'},
      {'category': 'Wood', 'number': '3W', 'model_name': 'Taylormade M1'},
      {'category': 'Utility', 'number': '9U', 'model_name': 'Taylormade M1'},
      {'category': 'Wedge', 'number': 'AW', 'model_name': 'Taylormade M1', 'loft': '52°'},
    ];

    final Map<String, List<Map<String, dynamic>>> grouped = {
      'Driver': [],
      'Woods / Hybrid': [],
      'Iron': [],
      'Wedge': [],
      'Putter': [],
    };

    for (var club in dummyClubs) {
      final cat = club['category'] as String;
      if (cat == 'Wood' && club['number'] == '1W') {
        grouped['Driver']?.add(club);
      } else if (cat == 'Wood' || cat == 'Utility' || cat == 'Hybrid') {
        grouped['Woods / Hybrid']?.add(club);
      } else if (cat == 'Iron' || cat == 'Iron Set') {
        grouped['Iron']?.add(club);
      } else if (cat == 'Wedge') {
        grouped['Wedge']?.add(club);
      } else if (cat == 'Putter') {
        grouped['Putter']?.add(club);
      }
    }

    if (mounted) {
      setState(() {
        _clubData = grouped;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const String bgImage = 'assets/images/myclub_top_bg.png';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // ★修正点: 右上のHistoryボタンを削除
        actions: const [], 
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ------------------------------------
          // 1. 固定背景画像
          // ------------------------------------
          Image.asset(
            bgImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: const Color(0xFF121212));
            },
          ),

          // ------------------------------------
          // 2. コンテンツ（スクロール可能）
          // ------------------------------------
          SingleChildScrollView(
            // ★修正点: 上部のパディングを増やして表示位置を下げる (100 -> 140)
            padding: const EdgeInsets.only(top: 140, left: 20, right: 20, bottom: 50),
            child: Column(
              children: [
                // タイトル
                const Text(
                  "What's in my bag",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Serif',
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2)),
                      Shadow(color: Colors.cyanAccent, blurRadius: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // モーダル風コンテナ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4), // 透過率高め
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildClubRowItem(
                        "Driver",
                        Icons.sports_golf,
                        Colors.blueAccent,
                        _clubData['Driver'] ?? [],
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageSearchScreen())),
                      ),
                      _buildDivider(),

                      _buildClubRowItem(
                        "Woods / Hybrid",
                        Icons.filter_hdr,
                        Colors.pinkAccent,
                        _clubData['Woods / Hybrid'] ?? [],
                        () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const MyclubWoodRegisterScreen()));
                          _fetchClubData();
                        },
                      ),
                      _buildDivider(),

                      _buildClubRowItem(
                        "Iron",
                        Icons.grid_view,
                        Colors.cyanAccent,
                        _clubData['Iron'] ?? [],
                        () {},
                      ),
                      _buildDivider(),

                      _buildClubRowItem(
                        "Wedge",
                        Icons.landscape,
                        Colors.greenAccent,
                        _clubData['Wedge'] ?? [],
                        () {},
                      ),
                      _buildDivider(),

                      _buildClubRowItem(
                        "Putter",
                        Icons.flag,
                        Colors.yellowAccent,
                        _clubData['Putter'] ?? [],
                        () {},
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // ★追加点: 画面下部の "My Club History" ボタン
                SizedBox(
                  width: double.infinity,
                  height: 56, // 少し高さを出して押しやすく
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyclubHistoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.history, color: Colors.white),
                    label: const Text(
                      "My Club History", 
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      )
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15), // 背景透過
                      foregroundColor: Colors.white,
                      elevation: 0,
                      side: const BorderSide(color: Colors.white60, width: 1.5), // 枠線
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // 丸みのあるデザイン
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.white30, height: 30);
  }

  Widget _buildClubRowItem(
    String title,
    IconData icon,
    Color neonColor,
    List<Map<String, dynamic>> items,
    VoidCallback onTapRegister,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: neonColor.withOpacity(0.6)),
                boxShadow: [BoxShadow(color: neonColor.withOpacity(0.3), blurRadius: 8)],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4, offset: const Offset(1, 1)),
                    Shadow(color: neonColor, blurRadius: 10),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: onTapRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonColor.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: neonColor),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text("登録", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: items.map((club) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 45,
                        child: Text(
                          "${club['number']}",
                          style: TextStyle(
                            color: neonColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            shadows: const [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          club['model_name'] ?? "",
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 14,
                            shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (club['loft'] != null)
                        Text(
                          club['loft'],
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ] else ...[
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 50.0),
            child: Text("登録なし", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ],
    );
  }
}