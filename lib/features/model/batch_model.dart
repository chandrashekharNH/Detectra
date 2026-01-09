import 'package:hive/hive.dart';

part 'batch_model.g.dart';

@HiveType(typeId: 1)
class BatchModel extends HiveObject {
  @HiveField(0)
  String batchId;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  BatchModel({
    required this.batchId,
    required this.name,
    required this.createdAt,
  });
}