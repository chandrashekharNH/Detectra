import 'dart:io';

import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class AutoCropper {
  static final DocumentScanner _scanner = DocumentScanner(
    options: DocumentScannerOptions(
      pageLimit: 1,
      isGalleryImport: false,
    ),
  );

  /// Attempts to crop ONLY if detected area looks like a label
  /// Otherwise returns original image
  static Future<File> cropLabelOnly(File originalFile) async {
    try {
      final result = await _scanner.scanDocument(
        originalFile.path,
      );

      if (result.pages.isEmpty) {
        return originalFile;
      }

      final croppedPath = result.pages.first.imagePath;
      final croppedFile = File(croppedPath);

      if (!croppedFile.existsSync()) {
        return originalFile;
      }

      // 🔒 Size heuristic
      final originalSize = originalFile.lengthSync();
      final croppedSize = croppedFile.lengthSync();

      // Labels are usually MUCH smaller than full photo
      final ratio = croppedSize / originalSize;

      // If cropped image is >45% of original → likely NOT a label
      if (ratio > 0.45) {
        return originalFile;
      }

      return croppedFile;
    } catch (e) {
      // Absolute safety fallback
      return originalFile;
    }
  }

  static void dispose() {
    _scanner.close();
  }
}