import 'dart:io';
import '../repositories/work_report_pdf_repository.dart';

class DownloadWorkReportPdfUseCase {
  final WorkReportPdfRepository repository;

  DownloadWorkReportPdfUseCase(this.repository);

  Future<File> call(int workReportId) async {
    return await repository.downloadWorkReportPdf(workReportId);
  }
}
