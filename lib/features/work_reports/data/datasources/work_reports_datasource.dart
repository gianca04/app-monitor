import 'package:dio/dio.dart';
import '../models/work_report.dart';
import 'package:monitor/core/constants/api_constants.dart';

abstract class WorkReportsDataSource {
  Future<List<WorkReport>> getWorkReports();
  Future<WorkReport> getWorkReport(int id);
  Future<WorkReport> createWorkReport(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature, List<Map<String, dynamic>> photos);
  Future<WorkReport> updateWorkReport(int id, WorkReport report);
  Future<void> deleteWorkReport(int id);
}

class WorkReportsDataSourceImpl implements WorkReportsDataSource {
  final Dio dio;

  WorkReportsDataSourceImpl(this.dio);

  @override
  Future<List<WorkReport>> getWorkReports() async {
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}');
    return (response.data['data'] as List).map((json) => WorkReport.fromJson(json)).toList();
  }

  @override
  Future<WorkReport> getWorkReport(int id) async {
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id');
    return WorkReport.fromJson(response.data['data']);
  }

  @override
  Future<WorkReport> createWorkReport(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature, List<Map<String, dynamic>> photos) async {
    final formData = FormData.fromMap({
      'project_id': projectId,
      'employee_id': employeeId,
      'name': name,
      'report_date': reportDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (description != null) 'description': description,
      if (tools != null) 'tools': tools,
      if (personnel != null) 'personnel': personnel,
      if (materials != null) 'materials': materials,
      if (suggestions != null) 'suggestions': suggestions,
      if (supervisorSignature != null) 'supervisor_signature': supervisorSignature,
      if (managerSignature != null) 'manager_signature': managerSignature,
    });

    // Add photos
    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];
      if (photo['descripcion'] != null) {
        formData.fields.add(MapEntry('photos[$i][descripcion]', photo['descripcion']));
      }
      if (photo['before_work_descripcion'] != null) {
        formData.fields.add(MapEntry('photos[$i][before_work_descripcion]', photo['before_work_descripcion']));
      }
      if (photo['photo'] != null) {
        formData.files.add(MapEntry('photos[$i][photo]', photo['photo']));
      }
      if (photo['before_work_photo'] != null) {
        formData.files.add(MapEntry('photos[$i][before_work_photo]', photo['before_work_photo']));
      }
    }

    final response = await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}',
      data: formData,
    );
    return WorkReport.fromJson(response.data['data']);
  }

  @override
  Future<WorkReport> updateWorkReport(int id, WorkReport report) async {
    final response = await dio.put(
      '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id',
      data: report.toJson(),
    );
    return WorkReport.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteWorkReport(int id) async {
    await dio.delete('${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id');
  }
}