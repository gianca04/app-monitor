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
    // Placeholder implementation
    return [];
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