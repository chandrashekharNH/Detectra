import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  CameraController? _controller;
  late final Box<Map> imageBox;

  bool _busy = false;
  int _nextIndex = 1;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    imageBox = Hive.box<Map>('imageBox');
    _loadNextIndex();
    _initCamera();
  }

  // ================= CAMERA =================
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera =
    cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  // ================= IMAGE INDEX =================
  void _loadNextIndex() {
    final existing =
    imageBox.values.where((e) => e['assetId'] == widget.assetId);
    _nextIndex = existing.length + 1;
  }

  // ================= DIRECTORY =================
  Future<Directory> _assetDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(
      p.join(
        base.path,
        'Detectra/batches/${widget.batchId}/${widget.assetId}',
      ),
    );
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  // ================= FEEDBACK =================
  void _showCapturedSnack(String fileName) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved $fileName'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ================= CAPTURE =================
  Future<void> _capture() async {
    if (_busy || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() => _busy = true);

    try {
      final picture = await _controller!.takePicture();
      final dir = await _assetDir();

      final fileName = 'IMG_${_nextIndex.toString().padLeft(3, '0')}.jpg';
      final savedPath = p.join(dir.path, fileName);

      await File(picture.path).copy(savedPath);

      final imageId = '${widget.assetId}_$_nextIndex';

      imageBox.put(imageId, {
        'imageId': imageId,
        'batchId': widget.batchId,
        'assetId': widget.assetId,
        'localPath': savedPath,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _nextIndex++;
      _showCapturedSnack(fileName);
    } catch (e) {
      debugPrint('Capture failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batch: ${widget.batchId}',
                style: const TextStyle(fontSize: 14)),
            Text('Asset: ${widget.assetId}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Stack(
        children: [
          CameraPreview(_controller!),

          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _busy ? null : _capture,
                child: _busy
                    ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                    : const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}