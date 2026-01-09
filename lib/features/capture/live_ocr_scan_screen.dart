import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LiveOcrScanScreen extends StatefulWidget {
  const LiveOcrScanScreen({super.key});

  @override
  State<LiveOcrScanScreen> createState() => _LiveOcrScanScreenState();
}

class _LiveOcrScanScreenState extends State<LiveOcrScanScreen> {
  CameraController? _controller;
  late final TextRecognizer _recognizer;

  bool _processing = false;
  bool _locked = false;
  String? _detectedText;

  final RegExp _assetRegex = RegExp(r'TSLC\d{3,6}');

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _recognizer =
        TextRecognizer(script: TextRecognitionScript.latin);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();

    await _controller!.startImageStream(_processFrame);

    if (mounted) setState(() {});
  }

  // ================= FRAME OCR =================
  Future<void> _processFrame(CameraImage image) async {
    if (_processing || _locked) return;

    _processing = true;

    try {
      final inputImage = _cameraImageToInputImage(image);
      if (inputImage == null) return;

      final result =
      await _recognizer.processImage(inputImage);

      for (final block in result.blocks) {
        for (final line in block.lines) {
          final normalized =
          line.text.replaceAll(' ', '').toUpperCase();

          final match =
          _assetRegex.firstMatch(normalized);
          if (match != null) {
            _onDetected(match.group(0)!);
            return;
          }
        }
      }
    } catch (_) {
      // ignore frame errors
    } finally {
      _processing = false;
    }
  }

  // ================= DETECTED =================
  Future<void> _onDetected(String assetId) async {
    _locked = true;
    _detectedText = assetId;

    HapticFeedback.heavyImpact();
    await _controller?.stopImageStream();

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Asset Detected'),
        content: Text(
          assetId,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Rescan'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pop(context, assetId);
    } else {
      _locked = false;
      _detectedText = null;
      await _controller?.startImageStream(_processFrame);
    }
  }

  // ================= IMAGE CONVERSION =================
  InputImage? _cameraImageToInputImage(CameraImage image) {
    try {
      final WriteBuffer buffer = WriteBuffer();
      for (final Plane plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }

      final bytes = buffer.done().buffer.asUint8List();
      final Size size =
      Size(image.width.toDouble(), image.height.toDouble());

      final camera = _controller!.description;
      final rotation =
          InputImageRotationValue.fromRawValue(
              camera.sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final format =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: size,
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
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
      appBar: AppBar(title: const Text('Live Asset Scan')),
      body: Stack(
        children: [
          CameraPreview(_controller!),

          // Scan box
          Center(
            child: Container(
              width: 260,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _detectedText == null
                      ? Colors.green
                      : Colors.orange,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Live detected overlay
          if (_detectedText != null)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _detectedText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1,
                    ),
                  ),
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
    _recognizer.close();
    super.dispose();
  }
}