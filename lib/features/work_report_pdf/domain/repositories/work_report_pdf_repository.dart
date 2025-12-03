import 'dart:io';

abstract class WorkReportPdfRepository {
  Future<File> downloadWorkReportPdf(int workReportId);
}
