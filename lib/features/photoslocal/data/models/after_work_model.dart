import 'package:hive/hive.dart';

part 'after_work_model.g.dart';

@HiveType(typeId: 1)
enum AfterWorkModel {
  @HiveField(0)
  yes,
  @HiveField(1)
  no,
}