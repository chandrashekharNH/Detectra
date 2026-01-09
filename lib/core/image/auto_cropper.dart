import 'dart:io';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image/image.dart' as img;

class AutoCropper {
  /// Auto-crop ONLY if it looks like a small label
  /// Returns original file if not confident
  static Future<File> cropLabelOnly(File original) async {
    final scanner = DocumentScanner(
      options: const DocumentScannerOptions(
        pageLimit: 1,
        mode: DocumentScannerMode.filter,
        isGalleryImport: false,
      ),
    );

    try {
      // ===== Decode original safely =====
      final originalBytes = await original.readAsBytes();
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) return original;

      final originalArea =
          originalImage.width * originalImage.height;

      // ===== Scan =====
      final result = await scanner.scanDocument(
        imagePath: original.path,
      );

      if (result.pages.isEmpty) {
        return original;
      }

      final croppedPath = result.pages.first.imagePath;
      final croppedFile = File(croppedPath);

      if (!croppedFile.existsSync()) {
        return original;
      }

      final croppedBytes = await croppedFile.readAsBytes();
      final croppedImage = img.decodeImage(croppedBytes);
      if (croppedImage == null) {
        return original;
      }

      final croppedArea =
          croppedImage.width * croppedImage.height;

      final ratio = croppedArea / originalArea;

      // 🔒 LABEL HEURISTIC
      // Labels usually occupy small area
      if (ratio > 0.4) {
        // Too big → likely full document
        return original;
      }

      return croppedFile;
    } catch (e) {
      // Fail silently → never block capture
      return original;
    } finally {
      // ✅ VERY IMPORTANT
      scanner.close();
    }
  }
}