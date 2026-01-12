import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../models/search_result.dart';

class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({super.key});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen> {
  File? _image;
  bool _loading = false;
  List<SearchResult> _results = [];
  
  // ApiServiceのインスタンスを作成（本来はProviderなどで渡すのがベストですが、まずはここで生成）
  final ApiService _apiService = ApiService();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _results.clear();
    });
  }

  Future<void> _search() async {
    if (_image == null) return;

    setState(() => _loading = true);

    try {
      // staticではなくインスタンス経由で呼び出す
      // uploadImage ではなく、リストを返す searchDriver を呼ぶ
      final results = await _apiService.searchDriver(_image!);
      
      setState(() => _results = results);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('検索失敗')));
    } finally {
      setState(() => _loading = false);
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
            if (_image != null)
              Image.file(_image!, height: 200),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('画像を選択'),
            ),

            ElevatedButton(
              onPressed: _search,
              child: const Text('検索'),
            ),

            const SizedBox(height: 16),

            if (_loading) const CircularProgressIndicator(),

            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final r = _results[index];
                  return Card(
                    child: ListTile(
                      title: Text('${r.brand} ${r.model}'),
                      subtitle:
                          Text('類似度: ${r.similarity.toStringAsFixed(3)}'),
                      leading: Text('#${r.rank}'),
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
