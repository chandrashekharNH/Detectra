import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // ✅ USE Map-based boxes (NO adapters)
  await Hive.openBox<Map>('batchBox');
  await Hive.openBox<Map>('assetBox');
  await Hive.openBox<Map>('imageBox');
  await Hive.openBox<String>('scannedAssetBox');

  runApp(const DetectraApp());
}