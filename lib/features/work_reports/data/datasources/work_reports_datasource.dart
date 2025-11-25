import 'package:dio/dio.dart';
import '../models/work_report.dart';
import 'package:monitor/core/constants/api_constants.dart';

abstract class WorkReportsDataSource {
  Future<List<WorkReport>> getWorkReports();
  Future<WorkReport> getWorkReport(int id);
  Future<WorkReport> createWorkReport(WorkReport report);
  Future<WorkReport> updateWorkReport(int id, WorkReport report);
  Future<void> deleteWorkReport(int id);
}

class WorkReportsDataSourceImpl implements WorkReportsDataSource {
  final Dio dio;

  WorkReportsDataSourceImpl(this.dio);

  @override
  Future<List<WorkReport>> getWorkReports() async {
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}');
    return (response.data as List).map((json) => WorkReport.fromJson(json)).toList();
  }

  @override
  Future<WorkReport> getWorkReport(int id) async {
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id');
    return WorkReport.fromJson(response.data);
  }

  @override
  Future<WorkReport> createWorkReport(WorkReport report) async {
    final response = await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}',
      data: report.toJson(),
    );
    return WorkReport.fromJson(response.data);
  }

  @override
  Future<WorkReport> updateWorkReport(int id, WorkReport report) async {
    final response = await dio.put(
      '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id',
      data: report.toJson(),
    );
    return WorkReport.fromJson(response.data);
  }

  @override
  Future<void> deleteWorkReport(int id) async {
    await dio.delete('${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id');
  }
}