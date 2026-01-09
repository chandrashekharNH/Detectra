import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrConfidence {
  static double score(TextLine line) {
    double s = 0.2;
    if (line.text.length >= 7) s += 0.2;
    if (line.boundingBox.height > 18) s += 0.3;
    if (RegExp(r'\d').hasMatch(line.text)) s += 0.2;
    return s.clamp(0, 1);
  }
}