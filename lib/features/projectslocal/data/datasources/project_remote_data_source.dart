import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';

abstract class ProjectRemoteDataSource {
  Future<ProjectsSyncResponse> getProjectsDiff(String? lastSync);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final Dio dio;

  ProjectRemoteDataSourceImpl({required this.dio});

  @override
  Future<ProjectsSyncResponse> getProjectsDiff(String? lastSync) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.projectsSyncEndpoint}';
    final queryParams = {'last_sync_at': lastSync ?? '2000-01-01T00:00:00Z'};

    try {
      final response = await dio.get(url, queryParameters: queryParams);
      print('Sincronización exitosa: ${response.data}');
      return ProjectsSyncResponse.fromJson(response.data);
    } catch (e) {
      print('Error en sincronización: $e');
      rethrow;
    }
  }
}

class ProjectsSyncResponse {
  final bool success;
  final SyncInfo syncInfo;
  final SyncData data;

  ProjectsSyncResponse({
    required this.success,
    required this.syncInfo,
    required this.data,
  });

  factory ProjectsSyncResponse.fromJson(Map<String, dynamic> json) {
    return ProjectsSyncResponse(
      success: json['success'] as bool,
      syncInfo: SyncInfo.fromJson(json['sync_info'] as Map<String, dynamic>),
      data: SyncData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class SyncInfo {
  final bool hasMore;
  final String nextSyncToken;

  SyncInfo({
    required this.hasMore,
    required this.nextSyncToken,
  });

  factory SyncInfo.fromJson(Map<String, dynamic> json) {
    return SyncInfo(
      hasMore: json['has_more'] as bool,
      nextSyncToken: json['next_sync_token'] as String,
    );
  }
}

class SyncData {
  final List<Map<String, dynamic>> upsert;
  final List<Map<String, dynamic>> delete;

  SyncData({
    required this.upsert,
    required this.delete,
  });

  factory SyncData.fromJson(Map<String, dynamic> json) {
    return SyncData(
      upsert: List<Map<String, dynamic>>.from(json['upsert'] ?? []),
      delete: List<Map<String, dynamic>>.from(json['delete'] ?? []),
    );
  }
}