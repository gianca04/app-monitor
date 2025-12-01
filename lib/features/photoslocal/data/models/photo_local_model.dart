import 'package:hive/hive.dart';
import 'after_work_model.dart';
import 'before_work_model.dart';
import 'timestamps_model.dart';

part 'photo_local_model.g.dart';

@HiveType(typeId: 4)
class PhotoLocalModel extends HiveObject {
  @HiveField(0)
  int? id;
  @HiveField(1)
  final int workReportId;
  @HiveField(2)
  final AfterWorkModel afterWork;
  @HiveField(3)
  final BeforeWorkModel beforeWork;
  @HiveField(4)
  final TimestampsModel timestamps;

  PhotoLocalModel({
    this.id,
    required this.workReportId,
    required this.afterWork,
    required this.beforeWork,
    required this.timestamps,
  });
}