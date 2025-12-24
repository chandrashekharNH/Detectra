import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class AssetOcrService {
  final _regex = RegExp(r'TSLC\d{3,6}');

  Future<String?> extractAssetId(File imageFile) async {
    final recognizer =
    TextRecognizer(script: TextRecognitionScript.latin);

    final inputImage = InputImage.fromFilePath(imageFile.path);
    final result = await recognizer.processImage(inputImage);

    for (final block in result.blocks) {
      for (final line in block.lines) {
        final text = line.text.replaceAll(' ', '');
        if (_regex.hasMatch(text)) {
          recognizer.close();
          return text;
        }
      }
    }

    recognizer.close();
    return null;
  }
}