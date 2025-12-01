import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';
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
    String? supervisorSignature,
    String? managerSignature,
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
    String? supervisorSignature,
    String? managerSignature,
  );
  Future<void> deleteWorkReport(int id);
}

class WorkReportsDataSourceImpl implements WorkReportsDataSource {
  final Dio dio;

  WorkReportsDataSourceImpl(this.dio);

  // Helper function to convert base64 data URL to bytes
  // Handles 1:1 ratio PNG images from Syncfusion SignaturePad
  Uint8List _base64DataUrlToBytes(String base64DataUrl) {
    // Remove the data URL prefix (e.g., "data:image/png;base64,")
    final base64String = base64DataUrl.split(',').last;
    return base64Decode(base64String);
  }

  dynamic _replaceUrls(dynamic data) {
    if (data is String) {
      final original = data;
      final replaced = data.replaceAll('127.0.0.1', '10.0.2.2');
      if (original != replaced) {
        print('🔄 [URL_REPLACE] Replaced: $original -> $replaced');
      }
      return replaced;
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
    String? supervisorSignature,
    String? managerSignature,
    List<Map<String, dynamic>> photos,
  ) async {
    try {
      print('🔍 [CREATE] Starting createWorkReport for project: $projectId, employee: $employeeId');

      final Map<String, dynamic> mapData = {
        'project_id': projectId.toString(),
        'employee_id': employeeId.toString(),
        'name': name,
        'report_date': reportDate,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (description != null) 'description': description,
        if (tools != null) 'tools': tools,
        if (personnel != null) 'personnel': personnel,
        if (materials != null) 'materials': materials,
        if (suggestions != null) 'suggestions': suggestions,
      };

      final formData = FormData.fromMap(mapData);

      if (supervisorSignature != null) {
        // Only send if it's a new base64 signature, not an existing URL
        if (!supervisorSignature.startsWith('http://') && !supervisorSignature.startsWith('https://')) {
          final signatureBytes = _base64DataUrlToBytes(supervisorSignature);
          formData.files.add(
            MapEntry(
              'supervisor_signature',
              MultipartFile.fromBytes(signatureBytes, filename: 'supervisor_signature.png'),
            ),
          );
          print('🔍 [CREATE] Added new supervisor_signature as file (${signatureBytes.length} bytes)');
        } else {
          print('🔍 [CREATE] Supervisor signature is existing URL, not sending');
        }
      }
      if (managerSignature != null) {
        // Only send if it's a new base64 signature, not an existing URL
        if (!managerSignature.startsWith('http://') && !managerSignature.startsWith('https://')) {
          final signatureBytes = _base64DataUrlToBytes(managerSignature);
          formData.files.add(
            MapEntry(
              'manager_signature',
              MultipartFile.fromBytes(signatureBytes, filename: 'manager_signature.png'),
            ),
          );
          print('🔍 [CREATE] Added new manager_signature as file (${signatureBytes.length} bytes)');
        } else {
          print('🔍 [CREATE] Manager signature is existing URL, not sending');
        }
      }

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

      print('🔍 [CREATE] FormData files count: ${formData.files.length}');
      print('📡 [CREATE] Sending POST to: ${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}');

      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}',
        data: formData,
      );

      print('✅ [CREATE] Response status: ${response.statusCode}');

      final replacedData = _replaceUrls(response.data);
      final workReport = WorkReport.fromJson(replacedData['data']);

      // Fetch the full work report to ensure photos are included with replaced URLs
      if (workReport.id != null) {
        print('🔄 [CREATE] Fetching full work report to load photos');
        return await getWorkReport(workReport.id!);
      } else {
        return workReport;
      }
    } on DioException catch (e) {
      print("❌ [CREATE] ERROR DIO: ${e.message}");
      if (e.response != null) {
        print("❌ [CREATE] Response status: ${e.response?.statusCode}");
        print("❌ [CREATE] Response data: ${e.response?.data}");
      }
      rethrow;
    } catch (e) {
      print("❌ [CREATE] ERROR: $e");
      rethrow;
    }
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
    String? supervisorSignature,
    String? managerSignature,
  ) async {
    try {
      print('🔍 [UPDATE] Starting updateWorkReport with id: $id');

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
        // Only send if it's a new base64 signature, not an existing URL
        if (!supervisorSignature.startsWith('http://') && !supervisorSignature.startsWith('https://')) {
          final signatureBytes = _base64DataUrlToBytes(supervisorSignature);
          formData.files.add(
            MapEntry(
              'supervisor_signature',
              MultipartFile.fromBytes(signatureBytes, filename: 'supervisor_signature.png'),
            ),
          );
          print('🔍 [UPDATE] Added new supervisor_signature as file (${signatureBytes.length} bytes)');
        } else {
          print('🔍 [UPDATE] Supervisor signature is existing URL, not sending');
        }
      }
      if (managerSignature != null) {
        // Only send if it's a new base64 signature, not an existing URL
        if (!managerSignature.startsWith('http://') && !managerSignature.startsWith('https://')) {
          final signatureBytes = _base64DataUrlToBytes(managerSignature);
          formData.files.add(
            MapEntry(
              'manager_signature',
              MultipartFile.fromBytes(signatureBytes, filename: 'manager_signature.png'),
            ),
          );
          print('🔍 [UPDATE] Added new manager_signature as file (${signatureBytes.length} bytes)');
        } else {
          print('🔍 [UPDATE] Manager signature is existing URL, not sending');
        }
      }

      print('🔍 [UPDATE] FormData files count: ${formData.files.length}');

      // Logs para verificar que ahora enviamos "12:07" y no "12:07:00"
      print(
        "📡 [UPDATE] Sending POST to: ${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id",
      );

      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$id',
        data: formData,
      );

      print('✅ [UPDATE] Response status: ${response.statusCode}');

      final replacedData = _replaceUrls(response.data);
      return WorkReport.fromJson(replacedData['data']);
    } on DioException catch (e) {
      print("❌ [UPDATE] ERROR DIO: ${e.message}");
      if (e.response != null) {
        print("❌ [UPDATE] Response status: ${e.response?.statusCode}");
        print("❌ [UPDATE] Response data: ${e.response?.data}");
      }
      rethrow;
    } catch (e) {
      print("❌ [UPDATE] ERROR: $e");
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
