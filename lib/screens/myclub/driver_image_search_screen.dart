import 'dart:io';
// 追加: JSONパース用
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../models/search_result.dart'; // SearchResultモデルが必要
import 'camera_screen.dart';

class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({super.key});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen> {
  File? _image;
  bool _loading = false;
  List<SearchResult> _results = []; // ここにデータが入ると画面が更新される

  // インスタンスを保持
  final ApiService _apiService = ApiService();

  Future<void> _pickImage() async {
    /*
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

     if (resultPath == null) return;

    setState(() {
      _image = File(picked.path);
      _results.clear(); // 新しい画像を選んだら結果をクリア
    });
    */

    // 【修正後】自作のカメラ画面へ移動し、結果（パス）を待つ
    final String? resultPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );

    if (resultPath != null) {
      setState(() {
        _image = File(resultPath);
        _results.clear();
      });
    // 撮影直後に自動検索したい場合はここで _search() を呼ぶ
    // _search(); 
    }
  }

  Future<void> _search() async {
    if (_image == null) return;

    setState(() => _loading = true);

    try {
      // 1. APIを呼び出す (main.py の /predict へ)
      // searchDriverが List<SearchResult> を返す作りならそのままで良いですが、
      // ここでは汎用的に修正します。
      final results = await _apiService.searchDriver(_image!);
      
      // 2. 結果をセットする
      setState(() {
        _results = results;
      });

    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('検索エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Image Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 画像プレビュー
            if (_image != null)
              SizedBox(
                height: 200,
                child: Image.file(_image!, fit: BoxFit.contain),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const Text('画像が選択されていません'),
              ),

            const SizedBox(height: 16),

            // 操作ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('撮影開始'),
                ),
                ElevatedButton.icon(
                  onPressed: (_image != null && !_loading) ? _search : null,
                  icon: const Icon(Icons.search),
                  label: _loading ? const Text('検索中...') : const Text('検索実行'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_loading) const LinearProgressIndicator(),

            const SizedBox(height: 16),

            // 結果リスト
            Expanded(
              child: _results.isEmpty && !_loading
                  ? const Center(child: Text('結果がここに表示されます'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final r = _results[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Text('#${r.rank}', style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text('${r.brand} ${r.model}'),
                            subtitle: Text('類似度: ${r.similarity.toStringAsFixed(3)}'),
                            // 必要に応じて画像を表示
                            // trailing: Image.network(...), 
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}