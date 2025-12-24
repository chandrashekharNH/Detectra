import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Open ALL boxes BEFORE app starts
  await Hive.openBox('batchBox');
  await Hive.openBox<String>('scannedAssetBox');
  await Hive.openBox('assetBox');
  await Hive.openBox('imageBox');

  runApp(const DetectraApp());
}