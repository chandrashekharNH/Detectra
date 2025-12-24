import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../capture/scan_asset_screen.dart';
import '../capture/capture_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Box batchBox;
  late final Box<String> assetBox;

  String? batchId;
  String? assetId;

  @override
  void initState() {
    super.initState();

    batchBox = Hive.box('batchBox');
    assetBox = Hive.box<String>('scannedAssetBox');

    _loadState();
  }

  void _loadState() {
    setState(() {
      batchId = batchBox.get('current_batch') ?? _createBatch();
      assetId = assetBox.get('current_asset');
    });
  }

  String _createBatch() {
    final batch = 'BATCH_${DateTime.now().millisecondsSinceEpoch}';
    batchBox.put('current_batch', batch);
    return batch;
  }

  Future<void> _scanAsset() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanAssetScreen()),
    );

    if (result != null) {
      assetBox.put('current_asset', result);
      setState(() => assetId = result);
    }
  }

  void _captureImages() {
    if (assetId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureScreen(
          batchId: batchId!,
          assetId: assetId!,
        ),
      ),
    );
  }

  void _bulkUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk upload queued (offline-first)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detectra'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------- Batch ----------
            Text(
              'Current Batch',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(batchId!, style: const TextStyle(fontSize: 16)),
            ),
            TextButton(
              onPressed: () {
                batchBox.delete('current_batch');
                assetBox.delete('current_asset');
                _loadState();
              },
              child: const Text('Create New Batch'),
            ),

            const Divider(height: 32),

            // ---------- Asset ----------
            Text(
              'Asset ID',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                assetId ?? 'No asset selected',
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Asset'),
              onPressed: _scanAsset,
            ),

            const SizedBox(height: 24),

            // ---------- Actions ----------
            ElevatedButton(
              onPressed: assetId == null ? null : _captureImages,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Capture Images'),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: _bulkUpload,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Bulk Upload'),
            ),
          ],
        ),
      ),
    );
  }
}