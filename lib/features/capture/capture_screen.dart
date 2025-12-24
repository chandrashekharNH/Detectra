import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';

class CaptureScreen extends StatefulWidget {
  final String batchId;
  final String assetId;

  const CaptureScreen({
    super.key,
    required this.batchId,
    required this.assetId,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late CameraController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller.initialize();
    setState(() => _isReady = true);
  }

  Future<void> _captureImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final assetDir =
    Directory('${dir.path}/${widget.batchId}/${widget.assetId}');
    if (!assetDir.existsSync()) assetDir.createSync(recursive: true);

    final imagePath =
        '${assetDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _controller.takePicture();
    final file = await _controller.takePicture();
    await file.saveTo(imagePath);

    /// Save locally
    final imageBox = Hive.box('imageBox');
    imageBox.add({
      'batchId': widget.batchId,
      'assetId': widget.assetId,
      'path': imagePath,
      'createdAt': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Image saved')));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Capture – ${widget.assetId}'),
      ),
      body: Stack(
        children: [
          CameraPreview(_controller),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _captureImage,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          )
        ],
      ),
    );
  }
}