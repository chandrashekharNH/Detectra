import 'package:hive/hive.dart';
part 'batch_model.g.dart';
part 'asset_model.g.dart';

@HiveType(typeId: 2)
class AssetModel extends HiveObject {
  @HiveField(0)
  String assetId;

  @HiveField(1)
  String batchId;

  @HiveField(2)
  DateTime createdAt;

  AssetModel({
    required this.assetId,
    required this.batchId,
    required this.createdAt,
  });
}