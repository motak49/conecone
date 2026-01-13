import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/activity.dart';
import '../models/search_result.dart';

class ApiService {
  // ※ AndroidエミュレーターからFastAPI(localhost:8000)につなぐ場合の設定
  final String predictUrl = 'http://10.0.2.2:8000/predict';
  
  // 既存のbaseUrl (Go/Node.js等のバックエンド用?)
  final String baseUrl = 'http://10.0.2.2:8080/api';
  
  // ... (fetchDashboardStats, uploadImage, postActivity はそのまま) ...

  // 【修正箇所】戻り値を String から List<SearchResult> に変更
  Future<List<SearchResult>> searchDriver(File imageFile) async {
    final url = Uri.parse(predictUrl);

    final request = http.MultipartRequest('POST', url);
    // backend/main.py の引数名 "file" に合わせる
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // 1. JSON文字列をデコード
        // response.body => '{"results": [{"rank":1, ...}, ...]}'
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // 2. "results" キーのリストを取り出す
        final List<dynamic> resultsJson = data['results'];

        // 3. SearchResult オブジェクトのリストに変換して返す
        return resultsJson
            .map((json) => SearchResult.fromJson(json))
            .toList();
      } else {
        throw Exception('Predict failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Search Error: $e');
    }
  }
}