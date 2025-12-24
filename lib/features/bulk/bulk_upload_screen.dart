import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  late final Box<Map> batchBox;
  late final Box<Map> assetBox;
  late final Box<Map> imageBox;

  bool _loading = false;
  String _status = 'No upload started';

  @override
  void initState() {
    super.initState();
    batchBox = Hive.box<Map>('batchBox');
    assetBox = Hive.box<Map>('assetBox');
    imageBox = Hive.box<Map>('imageBox');
  }

  // ================= ENTRY =================
  Future<void> _startBulkUpload() async {
    if (_loading) return;
    if (kIsWeb) {
      await _pickZip();
    } else {
      await _pickFolder();
    }
  }

  // ================= MOBILE: FOLDER =================
  Future<void> _pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;

    setState(() {
      _loading = true;
      _status = 'Reading batch folder...';
    });

    final batchId = p.basename(path);
    _createBatch(batchId, batchId);

    final batchDir = Directory(path);
    final assetDirs = batchDir.listSync().whereType<Directory>();

    for (final assetDir in assetDirs) {
      final assetId = p.basename(assetDir.path);
      _createAsset(assetId, batchId);

      int index = 1;
      for (final file in assetDir.listSync().whereType<File>()) {
        _createImage(batchId, assetId, file.path, index++);
      }
    }

    _finish();
  }

  // ================= WEB: ZIP =================
  Future<void> _pickZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );

    if (result == null || result.files.first.bytes == null) return;

    setState(() {
      _loading = true;
      _status = 'Extracting ZIP...';
    });

    final archive = ZipDecoder().decodeBytes(result.files.first.bytes!);
    final map = <String, Map<String, List<ArchiveFile>>>{};

    for (final file in archive) {
      if (!file.isFile) continue;
      final parts = p.split(file.name);
      if (parts.length < 3) continue;

      map.putIfAbsent(parts[0], () => {});
      map[parts[0]]!.putIfAbsent(parts[1], () => []);
      map[parts[0]]![parts[1]]!.add(file);
    }

    map.forEach((batchId, assets) {
      _createBatch(batchId, batchId);

      assets.forEach((assetId, files) {
        _createAsset(assetId, batchId);

        int index = 1;
        for (final _ in files) {
          final path = 'web://$batchId/$assetId/$index.jpg';
          _createImage(batchId, assetId, path, index++);
        }
      });
    });

    _finish();
  }

  // ================= DB =================
  void _createBatch(String id, String name) {
    if (batchBox.containsKey(id)) return;
    batchBox.put(id, {
      'batchId': id,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  void _createAsset(String id, String batchId) {
    if (assetBox.containsKey(id)) return;
    assetBox.put(id, {
      'assetId': id,
      'batchId': batchId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  void _createImage(String batchId, String assetId, String path, int index) {
    final id = '${assetId}_$index';
    if (imageBox.containsKey(id)) return;

    imageBox.put(id, {
      'imageId': id,
      'batchId': batchId,
      'assetId': assetId,
      'localPath': path,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  void _finish() {
    setState(() {
      _loading = false;
      _status = 'Bulk upload completed successfully';
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Upload')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Import assets in bulk',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: Text(kIsWeb ? 'Upload ZIP File' : 'Select Batch Folder'),
              onPressed: _loading ? null : _startBulkUpload,
            ),

            const SizedBox(height: 24),

            if (_loading) const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(_status),
          ],
        ),
      ),
    );
  }
}