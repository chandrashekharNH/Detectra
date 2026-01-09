import 'dart:typed_data';

class BulkPreviewBatch {
  String batchId;
  String batchName;
  List<BulkPreviewAsset> assets;

  BulkPreviewBatch({
    required this.batchId,
    required this.batchName,
    required this.assets,
  });
}

class BulkPreviewAsset {
  String assetId;
  List<BulkPreviewImage> images;

  BulkPreviewAsset({
    required this.assetId,
    required this.images,
  });
}

class BulkPreviewImage {
  final String name;
  final Uint8List bytes; // ALWAYS PRESENT (web + mobile)

  BulkPreviewImage({
    required this.name,
    required this.bytes,
  });
}