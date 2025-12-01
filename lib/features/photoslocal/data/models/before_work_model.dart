import 'package:hive/hive.dart';

part 'before_work_model.g.dart';

@HiveType(typeId: 2)
enum BeforeWorkModel {
  @HiveField(0)
  yes,
  @HiveField(1)
  no,
}