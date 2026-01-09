import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanAssetScreen extends StatefulWidget {
  const ScanAssetScreen({super.key});

  @override
  State<ScanAssetScreen> createState() => _ScanAssetScreenState();
}

class _ScanAssetScreenState extends State<ScanAssetScreen> {
  final MobileScannerController _scanner =
  MobileScannerController(facing: CameraFacing.back);

  bool _locked = false;

  // ---------- normalize ----------
  String _normalize(String v) =>
      v.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  bool _looksLikeAsset(String v) => v.length >= 5 && v.length <= 20;

  // ---------- CONFIRM ----------
  Future<void> _confirm(String assetId) async {
    _locked = true;
    await _scanner.stop();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Asset ID'),
        content: Text(
          assetId,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retry'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      Navigator.pop(context, assetId);
    } else {
      _locked = false;
      await _scanner.start();
    }
  }

  // ---------- BARCODE ----------
  void _onDetect(BarcodeCapture capture) {
    if (_locked) return;

    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;

      final value = _normalize(raw);
      if (_looksLikeAsset(value)) {
        _confirm(value);
        return;
      }
    }
  }

  // ---------- OCR (SAFE SINGLE CAPTURE) ----------
  Future<void> _scanPrintedLabel() async {
    try {
      final cameras = await availableCameras();
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      final picture = await controller.takePicture();
      await controller.dispose();

      final recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

      final image = InputImage.fromFilePath(picture.path);
      final result = await recognizer.processImage(image);
      recognizer.close();

      for (final block in result.blocks) {
        for (final line in block.lines) {
          final value = _normalize(line.text);
          if (_looksLikeAsset(value)) {
            _confirm(value);
            return;
          }
        }
      }

      _showMessage('No readable asset ID found');
    } catch (_) {
      _showMessage('Failed to scan label');
    }
  }

  // ---------- MANUAL ----------
  Future<void> _manualEntry() async {
    final ctrl = TextEditingController();

    final v = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Asset ID'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, _normalize(ctrl.text)),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (v != null && v.isNotEmpty && mounted) {
      Navigator.pop(context, v);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Asset')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scanner,
            onDetect: _onDetect,
          ),

          // ROI guide
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

          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              children: [
                const Text(
                  'Scan QR / Barcode or printed sticker',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _scanPrintedLabel,
                      child: const Text('Scan Label'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _manualEntry,
                      child: const Text('Manual Entry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }
}