import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/activity.dart';
import '../../models/search_result.dart';

class ApiService {
  // Androidエミュレーター用。実機ならPCのIPアドレス(例: 192.168.1.10)に変更
  // FastAPI (Python) 用
  final String predictUrl = 'http://10.0.2.2:8000/predict';
  
  // Go/Node.js 等のバックエンド用
  final String baseUrl = 'http://10.0.2.2:8080/api';
  
  // -------------------------------------------------
  // 1. ダッシュボード用データ取得
  // -------------------------------------------------
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final url = Uri.parse('$baseUrl/dashboard');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Dashboard Error: $e');
      return {}; 
    }
  }

  // -------------------------------------------------
  // 2. アップロード機能 (uploadImage)
  // ※ driver_upload_screen.dart で使用
  // -------------------------------------------------
  Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse('$baseUrl/upload');
    try {
      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url']; 
      } else {
        print('Upload Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }

  // -------------------------------------------------
  // 3. 画像検索機能 (searchDriver)
  // ※ driver_image_search_screen.dart で使用
  // -------------------------------------------------
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

  // -------------------------------------------------
  // 4. アクティビティ投稿
  // -------------------------------------------------
  Future<bool> postActivity(Activity activity) async {
    final url = Uri.parse('$baseUrl/activities');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(activity.toJson()),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Post Activity Failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Post Activity Error: $e');
      return false;
    }
  }
}