import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // 既存のDBファイル名をそのまま使用
    String path = join(documentsDirectory.path, "ajito_local.db");
    return await openDatabase(
      path, 
      version: 2, 
      onCreate: _onCreate,
      onConfigure: _onConfigure, // 外部キー制約を有効にする設定
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // --- 追加: 役満テーブル ---
    // 1. セッション（対局全体）テーブル
    await db.execute('''
      CREATE TABLE local_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        place_name TEXT,
        played_at TEXT,
        player_count INTEGER,
        player1_name TEXT,
        player2_name TEXT,
        player3_name TEXT,
        player4_name TEXT,
        has_chip INTEGER DEFAULT 0,
        chip_p1 INTEGER DEFAULT 0,
        chip_p2 INTEGER DEFAULT 0,
        chip_p3 INTEGER DEFAULT 0,
        chip_p4 INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // 2. ラウンド（各局のスコア）テーブル
    await db.execute('''
      CREATE TABLE local_hanchans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        hanchan_number INTEGER,
        score_p1 INTEGER,
        score_p2 INTEGER,
        score_p3 INTEGER,
        score_p4 INTEGER,
        FOREIGN KEY(session_id) REFERENCES local_sessions(id) ON DELETE CASCADE
      )
    ''');

    // 3. 役満テーブル（今回追加）
    await db.execute('''
      CREATE TABLE local_yakumans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        hanchan_number INTEGER,
        player_index INTEGER, -- 0=Player1, 1=Player2...
        yakuman_name TEXT,
        image_path TEXT,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY(session_id) REFERENCES local_sessions(id) ON DELETE CASCADE
      )
    ''');

    // 4. (参考) 汎用アクティビティテーブル（JSON保存用・今回は使用頻度低）
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        category TEXT NOT NULL,
        played_at TEXT NOT NULL,
        place_name TEXT,
        summary_text TEXT,
        primary_score INTEGER NOT NULL,
        image_urls TEXT,
        mahjong_data TEXT,
        golf_data TEXT,
        is_synced INTEGER DEFAULT 0, 
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');
  }

  // ==========================================================
  //  Mahjong Methods (UIからの呼び出しに対応)
  // ==========================================================

  // --- Session (対局作成・取得) ---

  // UI: insertSession という名前で呼ばれているため追加
  Future<int> insertSession(Map<String, dynamic> row) async {
    return await createSession(row);
  }

  Future<int> createSession(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('local_sessions', row);
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    Database db = await database;
    return await db.query('local_sessions', orderBy: 'played_at DESC');
  }

  Future<Map<String, dynamic>?> getSession(int sessionId) async {
    Database db = await database;
    final results = await db.query(
      'local_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // UI: insertHanchan という名前で呼ばれているため追加
  Future<int> insertHanchan(Map<String, dynamic> row) async {
    return await createHanchan(row);
  }

  Future<int> createHanchan(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('local_hanchans', row);
  }

  Future<List<Map<String, dynamic>>> getHanchans(int sessionId) async {
    Database db = await database;
    return await db.query(
      'local_hanchans',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'hanchan_number ASC', // ラウンド順に取得
    );
  }

  // --- Yakuman (役満記録) ---

  // UI: insertYakuman
  Future<int> insertYakuman(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('local_yakumans', row);
  }

  // UI: getYakumans (HistoryScreenのモーダル等で使用)
  Future<List<Map<String, dynamic>>> getYakumans(int sessionId) async {
    Database db = await database;
    return await db.query(
      'local_yakumans',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // --- Update (更新処理) ---

  // UI: updateSessionChips (最終チップ入力)
  Future<int> updateSessionChips(int sessionId, List<int> chips) async {
    Database db = await database;
    
    // プレイヤー人数に合わせてカラムを更新
    Map<String, dynamic> row = {
      'chip_p1': chips.length > 0 ? chips[0] : 0,
      'chip_p2': chips.length > 1 ? chips[1] : 0,
      'chip_p3': chips.length > 2 ? chips[2] : 0,
      'chip_p4': chips.length > 3 ? chips[3] : 0,
    };

    return await db.update(
      'local_sessions',
      row,
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // --- Delete (削除処理) ---

  // UI: deleteSession (対局削除)
  // 紐づくラウンドや役満もまとめて削除します
  Future<void> deleteSession(int sessionId) async {
    Database db = await database;
    
    await db.transaction((txn) async {
      // ON DELETE CASCADEを設定していますが、念のため明示的に消すロジック
      // 1. 役満削除
      await txn.delete(
        'local_yakumans',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      
      // 2. ラウンド削除
      await txn.delete(
        'local_hanchans',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );

      // 3. 本体削除
      await txn.delete(
        'local_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
  }

  // --- Statistics (集計・履歴表示用) ---

  // 指定年の全セッションと、計算済みの合計スコアを返す
  Future<List<Map<String, dynamic>>> getSessionSummaries(int year) async {
    Database db = await database;
    
    // 指定年のセッションを取得
    final sessions = await db.query(
      'local_sessions', 
      where: "strftime('%Y', played_at) = ?", 
      whereArgs: [year.toString()],
      orderBy: 'played_at DESC'
    );
    
    List<Map<String, dynamic>> results = [];

    for (var session in sessions) {
      int id = session['id'] as int;
      
      // ラウンドスコアの合計を計算
      final hanchans = await db.query('local_hanchans', where: 'session_id = ?', whereArgs: [id]);
      List<int> scoreTotals = [0, 0, 0, 0];
      
      for (var r in hanchans) {
        scoreTotals[0] += (r['score_p1'] as int? ?? 0);
        scoreTotals[1] += (r['score_p2'] as int? ?? 0);
        scoreTotals[2] += (r['score_p3'] as int? ?? 0);
        scoreTotals[3] += (r['score_p4'] as int? ?? 0);
      }
      
      // チップ情報の取得
      List<int> chipTotals = [
        session['chip_p1'] as int? ?? 0,
        session['chip_p2'] as int? ?? 0,
        session['chip_p3'] as int? ?? 0,
        session['chip_p4'] as int? ?? 0,
      ];

      // 総合計
      List<int> grandTotals = [
        scoreTotals[0] + chipTotals[0],
        scoreTotals[1] + chipTotals[1],
        scoreTotals[2] + chipTotals[2],
        scoreTotals[3] + chipTotals[3],
      ];

      // 役満があるかチェック
      final yakumans = await db.query('local_yakumans', where: 'session_id = ?', whereArgs: [id], limit: 1);
      bool hasYakuman = yakumans.isNotEmpty;

      Map<String, dynamic> summary = Map.of(session);
      summary['score_totals'] = scoreTotals; // 素点のみ
      summary['chip_totals'] = chipTotals;   // チップのみ
      summary['total_scores'] = grandTotals; // 合計
      summary['has_yakuman'] = hasYakuman;   // UI表示用フラグ

      results.add(summary);
    }
    return results;
  }

  // --- Dashboard Stats (ダッシュボード用集計) ---

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;

    // 1. 今年の合計スコア (素点 + チップ)
    // 現在の年を取得
    final now = DateTime.now();
    final startOfYear = "${now.year}-01-01";
    final endOfYear = "${now.year}-12-31 23:59:59";

    // セッションごとのスコアを集計するのは複雑なため、
    // getSessionSummaries を再利用してメモリ上で計算するのが安全かつ手軽です
    final summaries = await getSessionSummaries(now.year);

    int totalScore = 0;
    List<Map<String, dynamic>> chartData = [];
    List<Map<String, dynamic>> recentGames = [];

    // 日付の古い順に並べ替えて累積スコアを計算（グラフ用）
    // getSessionSummaries は日付降順（新しい順）で返ってくるので逆転させる
    List<Map<String, dynamic>> sortedSummaries = List.from(summaries.reversed);

    int cumulativeScore = 0;
    for (var s in sortedSummaries) {
      // 自分のスコア (Player1と仮定)
      List<int> totals = s['total_scores'];
      int myScore = totals[0]; 
      
      cumulativeScore += myScore;

      // グラフ用データ
      chartData.add({
        'played_at': s['played_at'],
        'score': myScore, // その日のスコア
        'cumulative_score': cumulativeScore, // 累積スコア
      });
    }

    // 今年の合計
    totalScore = cumulativeScore;

    // 直近の対局 (ダッシュボード表示用、新しい順に5件)
    recentGames = summaries.take(5).map((s) {
      List<int> totals = s['total_scores'];
      return {
        'id': s['id'],
        'place_name': s['place_name'],
        'played_at': s['played_at'],
        'score': totals[0], // 自分の合計スコア
      };
    }).toList();

    return {
      'total_score': totalScore,
      'chart_data': chartData,
      'recent_games': recentGames,
    };
  }

  // 他のファイルから DatabaseHelper.instance としてアクセスできるようにするためのゲッター
  static DatabaseHelper get instance => _instance;

  // ==========================================================
  //  New Activity Methods (Golf等用) - 追加部分
  // ==========================================================
  // 1. 新規作成 (Create)
  Future<int> createActivity(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('activities', row);
  }

  // 2. 全件取得 (Read List) - カテゴリ指定可
  Future<List<Map<String, dynamic>>> getActivities(String category) async {
    final db = await database;
    // 日付の新しい順に取得
    return await db.query(
      'activities',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'played_at DESC',
    );
  }

  // 3. ID指定取得 (Read Detail)
  Future<Map<String, dynamic>?> getActivity(int id) async {
    final db = await database;
    final maps = await db.query(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  // 4. 更新 (Update)
  Future<int> updateActivity(Map<String, dynamic> row) async {
    final db = await database;
    int id = row['id'];
    return await db.update(
      'activities',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 5. 削除 (Delete)
  Future<int> deleteActivity(int id) async {
    final db = await database;
    return await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}