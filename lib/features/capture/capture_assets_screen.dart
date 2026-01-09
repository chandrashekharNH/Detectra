import 'package:flutter/material.dart';

import 'capture_screen.dart';
import 'captured_assets_grid.dart';

class CaptureAssetsScreen extends StatelessWidget {
  final String batchId;
  final String assetId;

  const CaptureAssetsScreen({
    super.key,
    required this.batchId,
    required this.assetId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Asset')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white54,
                size: 72,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    child: const Text('Capture'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CaptureScreen(
                            batchId: batchId,
                            assetId: assetId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    child: const Text('View Captured'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CapturedAssetsGrid(
                            batchId: batchId,
                            assetId: assetId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}