import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // ✅ Open ALL boxes ONCE with CORRECT TYPES
  if (!Hive.isBoxOpen('batchBox')) {
    await Hive.openBox<Map>('batchBox');
  }

  if (!Hive.isBoxOpen('assetBox')) {
    await Hive.openBox<Map>('assetBox');
  }

  if (!Hive.isBoxOpen('imageBox')) {
    await Hive.openBox<Map>('imageBox');
  }

  if (!Hive.isBoxOpen('scannedAssetBox')) {
    await Hive.openBox<String>('scannedAssetBox');
  }

  runApp(const DetectraApp());
}