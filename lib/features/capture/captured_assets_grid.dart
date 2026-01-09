import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'capture_screen.dart';
import 'full_screen_image.dart';

class CapturedAssetsGrid extends StatefulWidget {
  final String batchId;
  final String assetId;

  const CapturedAssetsGrid({
    super.key,
    required this.batchId,
    required this.assetId,
  });

  @override
  State<CapturedAssetsGrid> createState() => _CapturedAssetsGridState();
}

class _CapturedAssetsGridState extends State<CapturedAssetsGrid> {
  late final Box<Map> imageBox;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    imageBox = Hive.box<Map>('imageBox');
  }

  List<Map> get images => imageBox.values
      .where((e) =>
  e['batchId'] == widget.batchId &&
      e['assetId'] == widget.assetId)
      .toList();

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete images?'),
        content: Text('Delete ${_selectedIds.length} selected images?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok == true) {
      for (final id in _selectedIds) {
        final img = imageBox.get(id);
        if (img != null) {
          File(img['localPath']).deleteSync();
          imageBox.delete(id);
        }
      }
      setState(() => _selectedIds.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final imgs = images;
    final paths = imgs.map((e) => e['localPath'] as String).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batch: ${widget.batchId}', style: const TextStyle(fontSize: 14)),
            Text('Asset: ${widget.assetId}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDelete),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upload coming soon')),
              );
            },
          ),
        ],
      ),
      body: imgs.isEmpty
          ? const Center(child: Text('No images captured'))
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: imgs.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (_, index) {
          final img = imgs[index];
          final id = img['imageId'];
          final selected = _selectedIds.contains(id);

          return GestureDetector(
            onLongPress: () {
              setState(() {
                selected ? _selectedIds.remove(id) : _selectedIds.add(id);
              });
            },
            onTap: () {
              if (_selectedIds.isNotEmpty) {
                setState(() {
                  selected ? _selectedIds.remove(id) : _selectedIds.add(id);
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImage(
                      imagePaths: paths,
                      initialIndex: index,
                    ),
                  ),
                );
              }
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(img['localPath']),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                if (selected)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.check_circle, color: Colors.white),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CaptureScreen(
                batchId: widget.batchId,
                assetId: widget.assetId,
              ),
            ),
          ).then((_) => setState(() {}));
        },
      ),
    );
  }
}