import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'bulk_models.dart';
import 'bulk_upload_preview_screen.dart';

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  bool loading = false;

  // Final parsed preview
  final List<BulkPreviewBatch> previewBatches = [];

  // ================= PICK ZIP =================
  Future<void> pickZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (result == null || result.files.first.bytes == null) return;

    setState(() {
      loading = true;
      previewBatches.clear();
    });

    final bytes = result.files.first.bytes!;
    final archive = ZipDecoder().decodeBytes(bytes);

    final Map<String, BulkPreviewBatch> batchMap = {};

    for (final file in archive) {
      if (!file.isFile) continue;

      final parts = p.split(file.name);

      // ❌ Ignore Mac junk
      if (parts.any((e) => e.startsWith('__MACOSX'))) continue;
      if (parts.any((e) => e == '.DS_Store')) continue;

      // Expect: Batches / Batch / Asset / Image
      final batchesIndex = parts.indexOf('Batches');
      if (batchesIndex == -1) continue;
      if (parts.length <= batchesIndex + 3) continue;

      final batchName = parts[batchesIndex + 1];
      final assetId = parts[batchesIndex + 2];
      final imageName = p.basename(file.name);

      // ---------- Batch ----------
      final batch = batchMap.putIfAbsent(
        batchName,
            () => BulkPreviewBatch(
          batchId: batchName,
          batchName: batchName,
          assets: [],
        ),
      );

      // ---------- Asset ----------
      final asset = batch.assets.firstWhere(
            (a) => a.assetId == assetId,
        orElse: () {
          final a = BulkPreviewAsset(assetId: assetId, images: []);
          batch.assets.add(a);
          return a;
        },
      );

      // ---------- Image (CRITICAL FIX) ----------
      asset.images.add(
        BulkPreviewImage(
          name: imageName,
          bytes: Uint8List.fromList(file.content as List<int>),
        ),
      );
    }

    previewBatches.addAll(batchMap.values);

    setState(() => loading = false);

    if (previewBatches.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BulkUploadPreviewScreen(
            batches: previewBatches,
          ),
        ),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Upload')),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
          icon: const Icon(Icons.upload),
          label: const Text('Upload ZIP'),
          onPressed: pickZip,
        ),
      ),
    );
  }
}