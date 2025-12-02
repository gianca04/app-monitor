import 'package:hive/hive.dart';

part 'timestamps_local_model.g.dart';

@HiveType(typeId: 8)
class TimestampsLocalModel extends HiveObject {
  @HiveField(0)
  final String? createdAt;

  @HiveField(1)
  final String? updatedAt;

  TimestampsLocalModel({this.createdAt, this.updatedAt});
}
