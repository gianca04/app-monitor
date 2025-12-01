import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';

abstract class ProjectRemoteDataSource {
  Future<ProjectsDiffResponse> getProjectsDiff(String? lastSync);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final Dio dio;

  ProjectRemoteDataSourceImpl({required this.dio});

  @override
  Future<ProjectsDiffResponse> getProjectsDiff(String? lastSync) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.projectsSyncEndpoint}';
    final queryParams = lastSync != null ? {'last_sync_at': lastSync} : null;

    final response = await dio.get(url, queryParameters: queryParams);

    return ProjectsDiffResponse(
      data: List<Map<String, dynamic>>.from(response.data['data']),
      meta: Map<String, dynamic>.from(response.data['meta']),
    );
  }
}

class ProjectsDiffResponse {
  final List<Map<String, dynamic>> data;
  final Map<String, dynamic> meta;

  ProjectsDiffResponse({required this.data, required this.meta});
}