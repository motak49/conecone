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
    String path = join(documentsDirectory.path, "conecone.db");
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
    // --- マイクラブテーブル ---
    await db.execute('''
      CREATE TABLE my_clubs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT NOT NULL,      -- Wood, Utility, Iron...
      number TEXT NOT NULL,        -- 1W, 5U, 7I...
      model_name TEXT NOT NULL,    -- モデル名
      loft TEXT,                   -- ロフト角 (任意)
      image_path TEXT,             -- 画像パス (任意)
      status TEXT DEFAULT 'current',                 -- 状態 (任意)
      sort_order INTEGEER DEFAULT 0,               -- 並び順 (任意)
      created_at TEXT DEFAULT (datetime('now'))
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

  // --- Yakuman (役満記録) ---

  // UI: insertYakuman

  // --- Update (更新処理) ---

  // UI: updateSessionChips (最終チップ入力)

  // --- Delete (削除処理) ---

  // UI: deleteSession (対局削除)
  // 紐づくラウンドや役満もまとめて削除します
  
  // --- Statistics (集計・履歴表示用) ---

  // 指定年の全セッションと、計算済みの合計スコアを返す

  // --- Dashboard Stats (ダッシュボード用集計) ---



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