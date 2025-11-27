import '../models/project.dart';
import '../models/quick_search_response.dart';

abstract class ProjectsDatasource {
  Future<List<Project>> getProjects();
  Future<Project?> getProject(int id);
  Future<void> createProject(Project project);
  Future<void> updateProject(Project project);
  Future<void> deleteProject(int id);
  Future<QuickSearchResponse> quickSearch(String query);
}