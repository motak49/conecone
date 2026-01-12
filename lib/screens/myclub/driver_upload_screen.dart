import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _image;
  String _result = '';
  bool _loading = false;

  // 【修正1】ApiServiceのインスタンスを作成
  // staticメソッドではなくなったため、この「_apiService」を通して機能を使います
  final ApiService _apiService = ApiService();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _result = '';
      });
    }
  }

  Future<void> _upload() async {
    if (_image == null) return;

    setState(() => _loading = true);

    try {
      // 【修正2】クラス名(ApiService)ではなく、インスタンス(_apiService)を使う
      final result = await _apiService.uploadImage(_image!);

      // nullチェックも入れておくと安全です
      setState(() => _result = result ?? 'アップロード完了（URLなし）');
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('画像を選択'),
            ),

            const SizedBox(height: 12),

            if (_image != null)
              Column(
                children: [
                  Image.file(
                    _image!,
                    height: 200,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '選択中: ${_image!.path.split('/').last}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _loading ? null : _upload,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('アップロード'),
            ),

            const SizedBox(height: 16),

            if (_result.isNotEmpty)
              Text(
                _result,
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
