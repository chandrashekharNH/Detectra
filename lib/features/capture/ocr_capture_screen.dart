import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../../core/ocr/asset_ocr_service.dart';

class OCRCaptureScreen extends StatefulWidget {
  const OCRCaptureScreen({super.key});

  @override
  State<OCRCaptureScreen> createState() =>
      _OCRCaptureScreenState();
}

class _OCRCaptureScreenState extends State<OCRCaptureScreen> {
  CameraController? _controller;
  bool _processing = false;

  final _ocrService = AssetOcrService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  // ================= OCR CAPTURE =================
  Future<void> _captureAndDetect() async {
    if (_processing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    setState(() => _processing = true);
    HapticFeedback.mediumImpact();

    try {
      final picture = await _controller!.takePicture();
      final file = File(picture.path);

      final assetId =
      await _ocrService.extractAssetId(file);

      if (!mounted) return;

      if (assetId != null) {
        Navigator.pop(context, assetId);
      } else {
        _showRetryDialog();
      }
    } catch (e) {
      _showRetryDialog();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Asset ID Not Detected'),
        content: const Text(
          'Please align the sticker clearly and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (_controller == null ||
        !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Asset Label')),
      body: Stack(
        children: [
          CameraPreview(_controller!),

          // 🔲 Sticker guide
          Center(
            child: Container(
              width: 260,
              height: 100,
              decoration: BoxDecoration(
                border:
                Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed:
              _processing ? null : _captureAndDetect,
              child: _processing
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Text('Capture & Detect'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}