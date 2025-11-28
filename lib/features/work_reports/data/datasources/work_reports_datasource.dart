import 'package:dio/dio.dart';
import '../models/work_report.dart';
import '../models/work_reports_response.dart';
import 'package:monitor/core/constants/api_constants.dart';

abstract class WorkReportsDataSource {
  Future<WorkReportsResponse> getWorkReports({String? dateFrom, String? dateTo});
  Future<WorkReport> getWorkReport(int id);
  Future<WorkReport> createWorkReport(int projectId, int employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature, List<Map<String, dynamic>> photos);
  Future<WorkReport> updateWorkReport(int id, int? projectId, int? employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature, List<Map<String, dynamic>> photos);
  Future<void> deleteWorkReport(int id);
}

class WorkReportsDataSourceImpl implements WorkReportsDataSource {
  final Dio dio;

  WorkReportsDataSourceImpl(this.dio);

  dynamic _replaceUrls(dynamic data) {
    if (data is String) {
      return data.replaceAll('127.0.0.1', '10.0.2.2');
    } else if (data is Map) {
      return data.map<String, dynamic>((key, value) => MapEntry(key as String, _replaceUrls(value)));
    } else if (data is List) {
      return data.map(_replaceUrls).toList();
    } else {
      return data;
    }
  }

  @override
  Future<WorkReportsResponse> getWorkReports({String? dateFrom, String? dateTo}) async {
    final queryParams = <String, dynamic>{};
    if (dateFrom != null) queryParams['date_from'] = dateFrom;
    if (dateTo != null) queryParams['date_to'] = dateTo;
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}', queryParameters: queryParams);
    final replacedData = _replaceUrls(response.data);
    return WorkReportsResponse.fromJson(replacedData);
  }

  @override
  Future<WorkReport> getWorkReport(int id) async {
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id');
    final replacedData = _replaceUrls(response.data);
    return WorkReport.fromJson(replacedData['data']);
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
    });

    // Add photos
    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];
      if (photo['descripcion'] != null && photo['descripcion'].isNotEmpty) {
        formData.fields.add(MapEntry('photos[$i][descripcion]', photo['descripcion']));
      }
      if (photo['before_work_descripcion'] != null && photo['before_work_descripcion'].isNotEmpty) {
        formData.fields.add(MapEntry('photos[$i][before_work_descripcion]', photo['before_work_descripcion']));
      }
      if (photo['photo'] != null) {
        formData.files.add(MapEntry('photos[$i][photo]', photo['photo']));
      }
      if (photo['before_work_photo'] != null) {
        formData.files.add(MapEntry('photos[$i][before_work_photo]', photo['before_work_photo']));
      }
    }

    print('Solicitud FormData fields: ${formData.fields}');
    print('Solicitud FormData files: ${formData.files.map((e) => '${e.key}: ${e.value.filename}').toList()}');

    final response = await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}',
      data: formData,
    );
    print('Create Work Report Response: ${response.data}');
    final replacedData = _replaceUrls(response.data);
    print('Replaced Data: $replacedData');
    return WorkReport.fromJson(replacedData['data']);
  }

  @override
  Future<WorkReport> updateWorkReport(int id, int? projectId, int? employeeId, String name, String reportDate, String? startTime, String? endTime, String? description, String? tools, String? personnel, String? materials, String? suggestions, MultipartFile? supervisorSignature, MultipartFile? managerSignature, List<Map<String, dynamic>> photos) async {
    final formData = FormData.fromMap({
      if (projectId != null) 'project_id': projectId.toString(),
      if (employeeId != null) 'employee_id': employeeId.toString(),
      'name': name,
      'report_date': reportDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (description != null) 'description': description,
      if (tools != null) 'tools': tools,
      if (personnel != null) 'personnel': personnel,
      if (materials != null) 'materials': materials,
      if (suggestions != null) 'suggestions': suggestions,
      '_method': 'PUT', // for Laravel or similar
    });

    if (supervisorSignature != null) {
      formData.files.add(MapEntry('supervisor_signature', supervisorSignature));
    }
    if (managerSignature != null) {
      formData.files.add(MapEntry('manager_signature', managerSignature));
    }

    // Photos are updated separately via photo endpoint
    // for (int i = 0; i < photos.length; i++) {
    //   final photo = photos[i];
    //   if (photo['id'] != null) {
    //     formData.fields.add(MapEntry('photos[$i][id]', photo['id'].toString()));
    //   }
    //   formData.fields.add(MapEntry('photos[$i][descripcion]', photo['descripcion']));
    //   formData.fields.add(MapEntry('photos[$i][before_work_descripcion]', photo['before_work_descripcion']));
    //   if (photo['photo'] != null) {
    //     formData.files.add(MapEntry('photos[$i][photo]', photo['photo']));
    //   }
    //   if (photo['before_work_photo'] != null) {
    //     formData.files.add(MapEntry('photos[$i][before_work_photo]', photo['before_work_photo']));
    //   }
    // }

    print('Update FormData fields: ${formData.fields}');
    print('Update FormData files: ${formData.files.map((e) => '${e.key}: ${e.value.filename}').toList()}');

    final response = await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id',
      data: formData,
    );
    final replacedData = _replaceUrls(response.data);
    return WorkReport.fromJson(replacedData['data']);
  }

  @override
  Future<void> deleteWorkReport(int id) async {
    await dio.delete('${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id');
  }
}