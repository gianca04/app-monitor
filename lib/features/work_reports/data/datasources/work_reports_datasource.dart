import 'package:dio/dio.dart';
import '../models/work_report.dart';
import '../models/work_reports_response.dart';
import 'package:monitor/core/constants/api_constants.dart';

abstract class WorkReportsDataSource {
  Future<WorkReportsResponse> getWorkReports({
    String? search,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  });
  Future<WorkReport> getWorkReport(int id);
  Future<WorkReport> createWorkReport(
    int projectId,
    int employeeId,
    String name,
    String reportDate,
    String? startTime,
    String? endTime,
    String? description,
    String? tools,
    String? personnel,
    String? materials,
    String? suggestions,
    MultipartFile? supervisorSignature,
    MultipartFile? managerSignature,
    List<Map<String, dynamic>> photos,
  );
  Future<WorkReport> updateWorkReport(
    int id,
    int projectId,
    int employeeId,
    String name,
    String reportDate,
    String? startTime,
    String? endTime,
    String? description,
    String? tools,
    String? personnel,
    String? materials,
    String? suggestions,
    MultipartFile? supervisorSignature,
    MultipartFile? managerSignature,
  );
  Future<void> deleteWorkReport(int id);
}

class WorkReportsDataSourceImpl implements WorkReportsDataSource {
  final Dio dio;

  WorkReportsDataSourceImpl(this.dio);

  dynamic _replaceUrls(dynamic data) {
    if (data is String) {
      return data.replaceAll('127.0.0.1', '10.0.2.2');
    } else if (data is Map) {
      return data.map<String, dynamic>(
        (key, value) => MapEntry(key as String, _replaceUrls(value)),
      );
    } else if (data is List) {
      return data.map(_replaceUrls).toList();
    } else {
      return data;
    }
  }

  @override
  Future<WorkReportsResponse> getWorkReports({
    String? search,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (dateFrom != null) queryParams['date_from'] = dateFrom;
    if (dateTo != null) queryParams['date_to'] = dateTo;
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (sortOrder != null) queryParams['sort_order'] = sortOrder;
    if (perPage != null) queryParams['per_page'] = perPage;
    if (page != null) queryParams['page'] = page;

    final response = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}',
      queryParameters: queryParams,
    );

    final replacedData = _replaceUrls(response.data);
    return WorkReportsResponse.fromJson(replacedData);
  }

  @override
  Future<WorkReport> getWorkReport(int id) async {
    final response = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id',
    );

    final replacedData = _replaceUrls(response.data);
    return WorkReport.fromJson(replacedData['data']);
  }

  @override
  Future<WorkReport> createWorkReport(
    int projectId,
    int employeeId,
    String name,
    String reportDate,
    String? startTime,
    String? endTime,
    String? description,
    String? tools,
    String? personnel,
    String? materials,
    String? suggestions,
    MultipartFile? supervisorSignature,
    MultipartFile? managerSignature,
    List<Map<String, dynamic>> photos,
  ) async {
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

    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];
      if (photo['descripcion'] != null && photo['descripcion'].isNotEmpty) {
        formData.fields.add(
          MapEntry('photos[$i][descripcion]', photo['descripcion']),
        );
      }
      if (photo['before_work_descripcion'] != null &&
          photo['before_work_descripcion'].isNotEmpty) {
        formData.fields.add(
          MapEntry(
            'photos[$i][before_work_descripcion]',
            photo['before_work_descripcion'],
          ),
        );
      }
      if (photo['photo'] != null) {
        formData.files.add(MapEntry('photos[$i][photo]', photo['photo']));
      }
      if (photo['before_work_photo'] != null) {
        formData.files.add(
          MapEntry('photos[$i][before_work_photo]', photo['before_work_photo']),
        );
      }
    }

    final response = await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}',
      data: formData,
    );

    final replacedData = _replaceUrls(response.data);

    return WorkReport.fromJson(replacedData['data']);
  }

  @override
  Future<WorkReport> updateWorkReport(
    int id,
    int projectId,
    int employeeId,
    String name,
    String reportDate,
    String? startTime,
    String? endTime,
    String? description,
    String? tools,
    String? personnel,
    String? materials,
    String? suggestions,
    MultipartFile? supervisorSignature,
    MultipartFile? managerSignature,
  ) async {
    try {
      // FUNCIÓN HELPER (Pequeña ayuda local para limpiar la hora)
      // Si la hora es "12:07:00", devuelve "12:07".
      String formatTime(String time) {
        if (time.length > 5) {
          return time.substring(0, 5);
        }
        return time;
      }

      final Map<String, dynamic> mapData = {
        'project_id': projectId.toString(),
        'employee_id': employeeId.toString(),
        'name': name,
        'report_date': reportDate,
        // APLICAMOS LA CORRECCIÓN AQUÍ:
        if (startTime != null) 'start_time': formatTime(startTime),
        if (endTime != null) 'end_time': formatTime(endTime),

        if (description != null) 'description': description,
        if (tools != null) 'tools': tools,
        if (personnel != null) 'personnel': personnel,
        if (materials != null) 'materials': materials,
        if (suggestions != null) 'suggestions': suggestions,
        "_method": "PUT",
      };

      final formData = FormData.fromMap(mapData);

      if (supervisorSignature != null) {
        formData.files.add(
          MapEntry('supervisor_signature', supervisorSignature),
        );
      }
      if (managerSignature != null) {
        formData.files.add(MapEntry('manager_signature', managerSignature));
      }

      // Logs para verificar que ahora enviamos "12:07" y no "12:07:00"
      print(
        "Enviando UPDATE a: ${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id",
      );
      print("Start Time enviado: ${mapData['start_time']}");

      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id',
        data: formData,
      );

      final replacedData = _replaceUrls(response.data);
      return WorkReport.fromJson(replacedData['data']);
    } on DioException catch (e) {
      print("ERROR DIO: ${e.message}");
      if (e.response != null) {
        // Si vuelve a fallar, seguiremos viendo por qué
        print("Data del error: ${e.response?.data}");
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteWorkReport(int id) async {
    await dio.delete(
      '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id',
    );
  }
}
