import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db_helper.dart';

// 詳細画面専用データモデル（複数メンバー対応版）
class GolfDetailData {
  final int id;
  final String placeName;
  final DateTime playedAt;
  final List<String> memberNames;
  final List<List<dynamic>> playerScores; // [PlayerIndex][HoleIndex] (プレイヤーごとの18ホールスコア)
  final List<int> pars;

  GolfDetailData({
    required this.id,
    required this.placeName,
    required this.playedAt,
    required this.memberNames,
    required this.playerScores,
    required this.pars,
  });

  factory GolfDetailData.fromMap(Map<String, dynamic> map) {
    // 1. golf_data (JSON) のデコード
    Map<String, dynamic> golfJson = {};
    if (map['golf_data'] != null) {
      if (map['golf_data'] is String) {
        try {
          golfJson = jsonDecode(map['golf_data']);
        } catch (_) {}
      } else {
        golfJson = map['golf_data'];
      }
    }

    // 2. メンバー名の取得
    List<String> parsedMembers = [];
    if (golfJson['member_names'] != null) {
      parsedMembers = List<String>.from(golfJson['member_names']);
    }

    // 3. スコアの取得 (プレイヤー別リストを想定: [[p1_h1...], [p2_h1...]])
    List<List<dynamic>> parsedPlayerScores = [];
    if (golfJson['scores'] != null && golfJson['scores'] is List) {
      for (var pScore in golfJson['scores']) {
        if (pScore is List) {
          parsedPlayerScores.add(List<dynamic>.from(pScore));
        }
      }
    }

    // もしメンバー名リストが空で、スコアリストがある場合は、仮の名前(Player 1...)を割り当てる
    if (parsedMembers.isEmpty && parsedPlayerScores.isNotEmpty) {
      for (int i = 0; i < parsedPlayerScores.length; i++) {
        parsedMembers.add(i == 0 ? "You" : "Player ${i + 1}");
      }
    }

    // 万が一スコアが何もない場合のフォールバック（自分用空データ）
    if (parsedPlayerScores.isEmpty) {
      parsedPlayerScores.add(List.filled(18, "-"));
      if (parsedMembers.isEmpty) parsedMembers.add("You");
    }

    // 4. Par情報の取得
    List<int> parsedPars = [];
    if (golfJson['pars'] != null && golfJson['pars'] is List) {
      parsedPars = List<int>.from(golfJson['pars']);
    }
    // 足りない場合はPar4で埋める
    if (parsedPars.length < 18) {
      parsedPars = List.filled(18, 4);
    }

    return GolfDetailData(
      id: map['id'],
      placeName: map['place_name'] ?? 'Unknown Course',
      playedAt: DateTime.parse(map['played_at']).toLocal(),
      memberNames: parsedMembers,
      playerScores: parsedPlayerScores,
      pars: parsedPars,
    );
  }
  
  // 指定したプレイヤーのトータルスコア計算
  int getTotalScore(int playerIndex) {
    if (playerIndex >= playerScores.length) return 0;
    int total = 0;
    for (var s in playerScores[playerIndex]) {
      int? sInt;
      if (s is int) sInt = s;
      else if (s is String) sInt = int.tryParse(s);
      
      if (sInt != null) total += sInt;
    }
    return total;
  }
}

class ScoreDetailScreen extends StatefulWidget {
  final int activityId;

  const ScoreDetailScreen({super.key, required this.activityId});

  @override
  State<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends State<ScoreDetailScreen> {
  GolfDetailData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetailFromLocalDB();
  }

  Future<void> _fetchDetailFromLocalDB() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'activities',
        where: 'id = ?',
        whereArgs: [widget.activityId],
      );

      if (maps.isNotEmpty) {
        final data = GolfDetailData.fromMap(maps.first);
        if (mounted) {
          setState(() {
            _data = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching detail: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    if (_data == null) {
      return _buildErrorScreen("データが見つかりませんでした");
    }

    final data = _data!;
    final dateStr = DateFormat('yyyy/MM/dd (E)', 'ja_JP').format(data.playedAt);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('ROUND MEMORY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ヘッダー情報
            _buildHeader(data, dateStr),
            const SizedBox(height: 24),

            // 2. 全員分のスコアカード
            const Text("SCORE TABLE", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            _buildMultiPlayerScoreTable(data),
            
            const SizedBox(height: 24),
            
            // (オプション) 補足情報があれば表示
            Center(
              child: Text(
                "Total Players: ${data.memberNames.length}",
                style: const TextStyle(color: Colors.white24),
              ),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorScreen(String msg) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(child: Text(msg, style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildHeader(GolfDetailData data, String dateStr) {
    // 自分のスコア（リストの最初と仮定）を表示、または代表スコアを表示
    int myScore = data.getTotalScore(0);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[900]!, const Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(data.placeName, 
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), 
            textAlign: TextAlign.center
          ),
          const SizedBox(height: 8),
          Text(dateStr, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          // メンバー一覧をチップで表示
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(data.memberNames.length, (index) {
              return Chip(
                label: Text(
                  "${data.memberNames[index]}: ${data.getTotalScore(index)}", 
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.white10,
                labelStyle: const TextStyle(color: Colors.white),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildMultiPlayerScoreTable(GolfDetailData data) {
    // 列定義: Hole, Par, Member1, Member2...
    List<DataColumn> columns = [
      const DataColumn(label: Text("Hole", style: TextStyle(color: Colors.amber))),
      const DataColumn(label: Text("Par", style: TextStyle(color: Colors.white70))),
    ];
    
    for (String name in data.memberNames) {
      columns.add(DataColumn(
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 60),
          child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        )
      ));
    }

    // 行データ生成: 1H ~ 18H
    List<DataRow> rows = [];
    int totalPar = 0;
    
    // ホールごと
    for (int i = 0; i < 18; i++) {
      int par = data.pars[i];
      totalPar += par;
      
      List<DataCell> cells = [
        DataCell(Text("${i + 1}", style: const TextStyle(color: Colors.white70))),
        DataCell(Text("$par", style: const TextStyle(color: Colors.white70))),
      ];
      
      // プレイヤーごと
      for (int pIdx = 0; pIdx < data.memberNames.length; pIdx++) {
        String displayScore = "-";
        Color textColor = Colors.white;
        FontWeight weight = FontWeight.normal;

        // データ範囲チェック
        if (pIdx < data.playerScores.length && i < data.playerScores[pIdx].length) {
          var val = data.playerScores[pIdx][i];
          displayScore = val.toString();
          
          // スコア比較（数値変換できる場合）
          int? sInt = int.tryParse(displayScore);
          if (sInt != null && sInt > 0) {
            if (sInt < par) { // バーディ以下
              textColor = Colors.amber;
              weight = FontWeight.bold;
            } else if (sInt > par) { // ボギー以上
              textColor = Colors.lightBlueAccent;
            }
          }
        }
        cells.add(DataCell(Text(displayScore, style: TextStyle(color: textColor, fontWeight: weight))));
      }
      rows.add(DataRow(cells: cells));
    }

    // TOTAL行の追加
    List<DataCell> totalCells = [
      const DataCell(Text("TTL", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
      DataCell(Text("$totalPar", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    ];
    
    for (int pIdx = 0; pIdx < data.memberNames.length; pIdx++) {
      int total = data.getTotalScore(pIdx);
      totalCells.add(DataCell(Text("$total", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
    }
    rows.add(DataRow(cells: totalCells, color: WidgetStateProperty.all(Colors.white10)));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(Colors.black12),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}