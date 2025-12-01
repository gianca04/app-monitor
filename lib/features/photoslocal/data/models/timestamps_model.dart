import 'package:hive/hive.dart';

part 'timestamps_model.g.dart';

@HiveType(typeId: 3)
class TimestampsModel extends HiveObject {
  @HiveField(0)
  final DateTime createdAt;
  @HiveField(1)
  final DateTime updatedAt;

  TimestampsModel({
    required this.createdAt,
    required this.updatedAt,
  });
}