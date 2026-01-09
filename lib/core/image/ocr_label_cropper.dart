import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrLabelCropper {
  static final _regex = RegExp(r'TSLC\d{3,6}');

  static Future<File> cropLabel(File image) async {
    final recognizer =
    TextRecognizer(script: TextRecognitionScript.latin);

    final input = InputImage.fromFilePath(image.path);
    final result = await recognizer.processImage(input);
    await recognizer.close();

    for (final block in result.blocks) {
      for (final line in block.lines) {
        final text = line.text.replaceAll(' ', '');
        if (_regex.hasMatch(text)) {
          // 🔒 For now: RETURN ORIGINAL IMAGE
          // Later: crop using native OpenCV / platform code
          return image;
        }
      }
    }
    return image;
  }
}