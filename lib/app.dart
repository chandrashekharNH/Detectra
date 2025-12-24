import 'package:flutter/material.dart';
import 'navigation/main_shell.dart';

class DetectraApp extends StatelessWidget {
  const DetectraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detectra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0A6CF1), // Detectra primary
      ),
      home: const MainShell(),
    );
  }
}