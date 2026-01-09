import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SmartAssetScanScreen extends StatefulWidget {
  const SmartAssetScanScreen({super.key});

  @override
  State<SmartAssetScanScreen> createState() => _SmartAssetScanScreenState();
}

class _SmartAssetScanScreenState extends State<SmartAssetScanScreen> {
  CameraController? _camera;
  final MobileScannerController _barcodeController =
  MobileScannerController();

  late final TextRecognizer _ocr;

  bool _processing = false;
  bool _locked = false;
  bool _torchOn = false;

  DateTime _lastFrame = DateTime.now();
  DateTime _lastLightCheck = DateTime.now();

  String? _detectedId;
  double _confidence = 0;

  final RegExp _assetRegex = RegExp(r'TSLC\d{3,6}');

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _ocr = TextRecognizer(script: TextRecognitionScript.latin);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera =
    cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

    _camera = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _camera!.initialize();
    await _camera!.startImageStream(_processFrame);

    if (mounted) setState(() {});
  }

  // ================= AUTO TORCH =================
  Future<void> autoTorch(CameraController cam) async {
    if (cam.value.exposureOffset < -1.0) {
      await cam.setFlashMode(FlashMode.torch);
    }
  }

  // ================= BARCODE =================
  void _onBarcode(BarcodeCapture capture) {
    if (_locked) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && _assetRegex.hasMatch(value)) {
        _finalDetect(value, confidence: 1.0);
        return;
      }
    }
  }

  // ================= OCR FRAME =================
  Future<void> _processFrame(CameraImage image) async {
    if (_processing || _locked) return;

    // 🔒 Throttle OCR (very important)
    if (DateTime.now().difference(_lastFrame).inMilliseconds < 400) {
      return;
    }
    _lastFrame = DateTime.now();

    _processing = true;

    await _autoTorchCheck();

    try {
      final inputImage = _cameraImageToInputImage(image);
      if (inputImage == null) return;

      final result = await _ocr.processImage(inputImage);

      for (final block in result.blocks) {
        for (final line in block.lines) {
          final text = line.text.replaceAll(' ', '').toUpperCase();
          final match = _assetRegex.firstMatch(text);

          if (match != null) {
            final score = _estimateConfidence(line);

            if (mounted) {
              setState(() => _confidence = score);
            }

            if (score >= 0.65) {
              _finalDetect(match.group(0)!, confidence: score);
            }
            return;
          }
        }
      }
    } finally {
      _processing = false;
    }
  }

  // ================= CONFIDENCE =================
  double _estimateConfidence(TextLine line) {
    double score = 0.3;

    if (line.text.length >= 7) score += 0.2;
    if (line.boundingBox.height > 18) score += 0.3;
    if (RegExp(r'\d').hasMatch(line.text)) score += 0.2;

    return score.clamp(0, 1);
  }

  // ================= FINAL DETECT =================
  Future<void> _finalDetect(
      String id, {
        required double confidence,
      }) async {
    _locked = true;
    _detectedId = id;
    _confidence = confidence;

    HapticFeedback.heavyImpact();

    await _camera?.stopImageStream();
    await _barcodeController.stop();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Asset Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              id,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: confidence),
            const SizedBox(height: 4),
            Text(
              'Confidence ${(confidence * 100).toInt()}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
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

    if (ok == true) {
      Navigator.pop(context, id);
    } else {
      _locked = false;
      _detectedId = null;
      _confidence = 0;
      await _camera?.startImageStream(_processFrame);
      await _barcodeController.start();
    }
  }

  // ================= IMAGE CONVERSION =================
  InputImage? _cameraImageToInputImage(CameraImage image) {
    try {
      final WriteBuffer buffer = WriteBuffer();
      for (final plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }

      final bytes = buffer.done().buffer.asUint8List();
      final size = Size(image.width.toDouble(), image.height.toDouble());

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: size,
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
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
    if (_camera == null || !_camera!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Asset Scan'),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () async {
              if (_camera == null) return;
              _torchOn = !_torchOn;
              await _camera!.setFlashMode(
                _torchOn ? FlashMode.torch : FlashMode.off,
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_camera!),

          MobileScanner(
            controller: _barcodeController,
            onDetect: _onBarcode,
          ),

          Center(
            child: Container(
              width: 260,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              children: [
                LinearProgressIndicator(value: _confidence),
                const SizedBox(height: 4),
                Text(
                  _detectedId ?? 'Scanning...',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _camera?.setFlashMode(FlashMode.off);
    _camera?.dispose();
    _barcodeController.dispose();
    _ocr.close();
    super.dispose();
  }
}