import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Detectra',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Detectra is an offline-first mobile app that captures asset images, '
                  'detects physical defects, and generates automated inspection reports.',
            ),
            SizedBox(height: 20),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('© Trigent Software'),
          ],
        ),
      ),
    );
  }
}