// lib/myclub/camera_screen.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // 利用可能なカメラを取得
    _cameras = await availableCameras();
    
    if (_cameras != null && _cameras!.isNotEmpty) {
      // 0番目（通常は背面カメラ）を選択
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high, // 画質設定
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      
      // 写真を撮影
      final image = await _controller!.takePicture();

      if (!mounted) return;

      // 撮影した画像のパスを前の画面に戻す
      Navigator.pop(context, image.path);

    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _controller != null) {
            // ===============================================
            // ここがポイント: カメラ映像の上に画像を重ねる
            // ===============================================
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. カメラのプレビュー映像
                CameraPreview(_controller!),

                // 2. ガイド用の輪郭画像 (透過PNG)
                Center(
                  child: Opacity(
                    opacity: 0.5, // 半透明にして背景を見やすくする
                    child: Image.asset(
                      'assets/images/guide_outline.png', // 作成したガイド画像
                      width: 300, // 画面サイズに合わせて調整
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                // 3. 撮影ガイドテキスト
                const Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Text(
                    "枠に合わせて撮影してください",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ),

                // 4. 撮影ボタン
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: _takePicture,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.camera_alt, color: Colors.black),
                    ),
                  ),
                ),
                
                // 5. 戻るボタン
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}