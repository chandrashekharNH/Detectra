import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'bulk_models.dart';

class BulkUploadPreviewScreen extends StatefulWidget {
  final List<BulkPreviewBatch> batches;
  const BulkUploadPreviewScreen({super.key, required this.batches});

  @override
  State<BulkUploadPreviewScreen> createState() =>
      _BulkUploadPreviewScreenState();
}

class _BulkUploadPreviewScreenState extends State<BulkUploadPreviewScreen> {
  final batchBox = Hive.box<Map>('batchBox');
  final assetBox = Hive.box<Map>('assetBox');
  final imageBox = Hive.box<Map>('imageBox');

  bool saving = false;

  Future<void> _saveAll() async {
    setState(() => saving = true);

    for (final batch in widget.batches) {
      batchBox.put(batch.batchId, {
        'batchId': batch.batchId,
        'name': batch.batchName,
        'createdAt': DateTime.now().toIso8601String(),
      });

      for (final asset in batch.assets) {
        assetBox.put(asset.assetId, {
          'assetId': asset.assetId,
          'batchId': batch.batchId,
          'createdAt': DateTime.now().toIso8601String(),
        });

        for (int i = 0; i < asset.images.length; i++) {
          imageBox.put('${asset.assetId}_$i', {
            'imageId': '${asset.assetId}_$i',
            'batchId': batch.batchId,
            'assetId': asset.assetId,
            'bytes': asset.images[i].bytes,
            'name': asset.images[i].name,
          });
        }
      }
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Upload Preview')),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: saving ? null : _saveAll,
          child: const Text('Confirm & Import'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: widget.batches.map((b) {
          return ExpansionTile(
            title: Text(b.batchName),
            children: b.assets.map((a) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.assetId,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: a.images.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                    ),
                    itemBuilder: (_, i) => Image.memory(
                      a.images[i].bytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}