import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanAssetScreen extends StatefulWidget {
  const ScanAssetScreen({super.key});

  @override
  State<ScanAssetScreen> createState() => _ScanAssetScreenState();
}

class _ScanAssetScreenState extends State<ScanAssetScreen> {
  final MobileScannerController _barcodeController =
  MobileScannerController(facing: CameraFacing.back);

  CameraController? _cameraController;
  bool _locked = false;

  final RegExp _assetRegex = RegExp(r'TSLC\d{3,6}');

  bool _isValid(String text) =>
      _assetRegex.hasMatch(text.replaceAll(' ', ''));

  // ================= CONFIRM =================
  Future<void> _confirm(String assetId) async {
    _locked = true;
    await _barcodeController.stop();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Asset ID Detected'),
        content: Text(
          assetId,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
      Hive.box<String>('scannedAssetBox')
          .put('current_asset', assetId);

      Navigator.pop(context, assetId);
    } else {
      _locked = false;
      await _barcodeController.start();
    }
  }

  // ================= BARCODE =================
  void _onBarcode(BarcodeCapture capture) {
    if (_locked) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && _isValid(value)) {
        _confirm(value);
        return;
      }
    }
  }

  // ================= OCR FALLBACK =================
  Future<void> _runOcrFallback() async {
    if (_locked) return;

    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    final file = await _cameraController!.takePicture();

    final recognizer =
    TextRecognizer(script: TextRecognitionScript.latin);

    final inputImage = InputImage.fromFilePath(file.path);
    final result = await recognizer.processImage(inputImage);

    for (final block in result.blocks) {
      for (final line in block.lines) {
        final text = line.text.replaceAll(' ', '');
        if (_isValid(text)) {
          recognizer.close();
          await _confirm(text);
          return;
        }
      }
    }

    recognizer.close();

    if (mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Asset Not Detected'),
          content: const Text(
              'Please align the sticker clearly and try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _locked = false;
                _barcodeController.start();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  // ================= AUTO OCR TRIGGER =================
  @override
  void initState() {
    super.initState();

    // OCR fallback after 4 seconds if barcode fails
    Future.delayed(const Duration(seconds: 4), () {
      if (!_locked) {
        _runOcrFallback();
      }
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Asset')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _barcodeController,
            onDetect: _onBarcode,
          ),

          // Scan guide
          Center(
            child: Container(
              width: 260,
              height: 90,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align asset barcode or sticker inside the box',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }
}