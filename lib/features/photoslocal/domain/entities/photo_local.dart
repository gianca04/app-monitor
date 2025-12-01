import 'after_work.dart';
import 'before_work.dart';
import 'timestamps.dart';

class PhotoLocal {
  final int? id;
  final int workReportId;
  final AfterWork afterWork;
  final BeforeWork beforeWork;
  final Timestamps timestamps;

  PhotoLocal({
    this.id,
    required this.workReportId,
    required this.afterWork,
    required this.beforeWork,
    required this.timestamps,
  });
}