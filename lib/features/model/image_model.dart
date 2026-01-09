import 'package:hive/hive.dart';

part 'image_model.g.dart';
part 'batch_model.g.dart';
@HiveType(typeId: 3)
class ImageModel extends HiveObject {
  @HiveField(0)
  String imageId;

  @HiveField(1)
  String batchId;

  @HiveField(2)
  String assetId;

  @HiveField(3)
  String localPath;

  @HiveField(4)
  DateTime createdAt;

  ImageModel({
    required this.imageId,
    required this.batchId,
    required this.assetId,
    required this.localPath,
    required this.createdAt,
  });
}