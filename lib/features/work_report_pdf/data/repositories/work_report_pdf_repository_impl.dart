import 'dart:io';
import '../../domain/repositories/work_report_pdf_repository.dart';
import '../datasources/work_report_pdf_datasource.dart';

class WorkReportPdfRepositoryImpl implements WorkReportPdfRepository {
  final WorkReportPdfDataSource dataSource;

  WorkReportPdfRepositoryImpl(this.dataSource);

  @override
  Future<File> downloadWorkReportPdf(int workReportId) async {
    return await dataSource.downloadWorkReportPdf(workReportId);
  }
}
