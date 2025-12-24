import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../capture/scan_asset_screen.dart';
import '../capture/capture_screen.dart';
import '../bulk/bulk_upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Map> batchBox;
  late Box<Map> assetBox;

  String? selectedBatchId;
  String? selectedAssetId;

  @override
  void initState() {
    super.initState();
    batchBox = Hive.box<Map>('batchBox');
    assetBox = Hive.box<Map>('assetBox');
    _initBatch();
  }

  // ================= INIT =================
  void _initBatch() {
    if (batchBox.isEmpty) {
      _createBatch(auto: true);
    } else {
      selectedBatchId = batchBox.keys.first as String;
    }
  }

  void _createBatch({bool auto = false}) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final batchId = 'BATCH_$ts';

    batchBox.put(batchId, {
      'batchId': batchId,
      'name': auto ? 'Batch-$ts' : 'New Batch',
      'createdAt': ts,
    });

    setState(() {
      selectedBatchId = batchId;
      selectedAssetId = null;
    });
  }

  // ================= DATA =================
  List<Map<String, dynamic>> get batches =>
      batchBox.values.map((e) => Map<String, dynamic>.from(e)).toList();

  List<Map<String, dynamic>> get assets {
    if (selectedBatchId == null) return [];
    return assetBox.values
        .where((a) => a['batchId'] == selectedBatchId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ================= CREATE BATCH =================
  Future<void> _createBatchWithName() async {
    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Batch'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter batch name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true || controller.text.trim().isEmpty) return;

    final ts = DateTime.now().millisecondsSinceEpoch;
    final batchId = 'BATCH_$ts';

    batchBox.put(batchId, {
      'batchId': batchId,
      'name': controller.text.trim(),
      'createdAt': ts,
    });

    setState(() {
      selectedBatchId = batchId;
      selectedAssetId = null;
    });
  }

  // ================= EDIT BATCH =================
  Future<void> _editBatch() async {
    if (selectedBatchId == null) return;

    final batch = batches.firstWhere((b) => b['batchId'] == selectedBatchId);
    final ctrl = TextEditingController(text: batch['name']);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Batch Name'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      batchBox.put(selectedBatchId, {
        ...batch,
        'name': ctrl.text.trim(),
      });
      setState(() {});
    }
  }

  // ================= SCAN ASSET =================
  Future<void> _scanAsset() async {
    if (selectedBatchId == null) return;

    final assetId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanAssetScreen()),
    );

    if (assetId == null) return;

    assetBox.put(assetId, {
      'assetId': assetId,
      'batchId': selectedBatchId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    setState(() => selectedAssetId = assetId);
  }

  // ================= CAPTURE =================
  void _capture() {
    if (selectedBatchId == null || selectedAssetId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureScreen(
          batchId: selectedBatchId!,
          assetId: selectedAssetId!,
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final batchAssets = assets;

    return Scaffold(
      appBar: AppBar(title: const Text('Detectra')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ===== BATCH =====
          const Text('Batch'),
          const SizedBox(height: 8),

          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: selectedBatchId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: batches.map((b) {
                    return DropdownMenuItem<String>(
                      value: b['batchId'],
                      child: Text(b['name']),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedBatchId = v;
                      selectedAssetId = null;
                    });
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editBatch,
            ),
          ]),

          const SizedBox(height: 8),

          Row(children: [
            ElevatedButton(
              onPressed: _createBatchWithName,
              child: const Text('Create Batch'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BulkUploadScreen()),
                );
              },
              child: const Text('Bulk Upload'),
            ),
          ]),

          const SizedBox(height: 24),

          // ===== ASSET =====
          const Text('Asset'),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: batchAssets.isEmpty
                ? const Text('No assets associated with this batch')
                : DropdownButton<String>(
              value: selectedAssetId,
              isExpanded: true,
              underline: const SizedBox(),
              items: batchAssets.map((a) {
                return DropdownMenuItem<String>(
                  value: a['assetId'],
                  child: Text(a['assetId']),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedAssetId = v),
            ),
          ),

          const SizedBox(height: 16),

          // ===== ACTIONS =====
          ElevatedButton(
            onPressed: selectedBatchId == null ? null : _scanAsset,
            child: const Text('Scan Asset'),
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: selectedAssetId == null ? null : _capture,
            child: const Text('Capture Images'),
          ),
        ]),
      ),
    );
  }
}