import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          BatchCard(batchName: 'BATCH-001'),
          BatchCard(batchName: 'BATCH-002'),
        ],
      ),
    );
  }
}

class BatchCard extends StatefulWidget {
  final String batchName;
  const BatchCard({super.key, required this.batchName});

  @override
  State<BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends State<BatchCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.batchName),
            subtitle: const Text('Created: Today'),
            trailing: IconButton(
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => expanded = !expanded),
            ),
          ),
          if (expanded) const AssetItem(),
        ],
      ),
    );
  }
}

class AssetItem extends StatelessWidget {
  const AssetItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Asset: ASSET-123'),
          const SizedBox(height: 6),
          Row(
            children: const [
              Chip(label: Text('Processing')),
              Spacer(),
              TextButton(child: Text('Feedback'), onPressed: null),
            ],
          ),
        ],
      ),
    );
  }
}