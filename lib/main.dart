import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ★追加: 多言語対応パッケージ
import 'package:intl/date_symbol_data_local.dart'; // 日付フォーマット用
import 'screens/home_screen.dart'; // インポート先を変更

void main() async {
  // Flutterエンジンの初期化待ち
  WidgetsFlutterBinding.ensureInitialized();
  
  // 日付フォーマット（日本語）の初期化
  await initializeDateFormatting('ja_JP', null);

  runApp(const AjitoApp());
}

class AjitoApp extends StatelessWidget {
  const AjitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'コネコネ',
      debugShowCheckedModeBanner: false,

      // ★追加: 日本語化のための設定
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'), // 日本語をサポート
      ],
      // ロケールを日本に固定（スマホ本体の設定に関わらず日本語で表示したい場合）
      locale: const Locale('ja', 'JP'),
      
      // アプリ全体のテーマ設定
      theme: ThemeData(
        brightness: Brightness.dark, 
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        
        // カードのデザイン設定
        // ★最新版Flutterに合わせて修正しました
        cardTheme: CardThemeData( // ← CardThemeData に変更
          color: Colors.white.withValues(alpha: 0.1), // ← withValues(alpha: 0.1) に変更
          elevation: 0,
        ),
      ),
      
      // ホーム画面をダッシュボードに設定
      home: const HomeScreen(),
    );
  }
}