import 'package:dio/dio.dart';
import 'projects_datasource.dart';
import '../models/project.dart';
import '../models/quick_search_response.dart';
import 'package:monitor/core/constants/api_constants.dart';

class ProjectsDatasourceImpl implements ProjectsDatasource {
  final Dio dio;

  ProjectsDatasourceImpl(this.dio);

  @override
  Future<List<Project>> getProjects() async {
    try {
      final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.projectsEndpoint}');
      
      // Imprimir por consola para visualizar el JSON recibido
      // print('🚀 [PROJECTS JSON]: ${response.data}');

      // Adaptar según la estructura de respuesta del backend de Laravel
      // Usualmente viene paginado o envuelto en "data"
      final List<dynamic> dataList = response.data['data'] ?? response.data;
      
      return dataList.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      // print('❌ [PROJECTS ERROR]: $e');
      rethrow;
    }
  }

  @override
  Future<Project?> getProject(int id) async {
    // Placeholder implementation
    return null;
  }

  @override
  Future<void> createProject(Project project) async {
    // Placeholder implementation
  }

  @override
  Future<void> updateProject(Project project) async {
    // Placeholder implementation
  }

  @override
  Future<void> deleteProject(int id) async {
    // Placeholder implementation
  }

  @override
  Future<QuickSearchResponse> quickSearch(String query) async {
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.projectsEndpoint}/quick-search', queryParameters: {'query': query});
    return QuickSearchResponse.fromJson(response.data);
  }
}