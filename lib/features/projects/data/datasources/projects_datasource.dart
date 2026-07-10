import '../models/project.dart';
import '../models/projects_response.dart';
import '../models/quick_search_response.dart';

abstract class ProjectsDatasource {
  Future<ProjectsResponse> getProjects({int page = 1, int perPage = 15});
  Future<Project?> getProject(int id);
  Future<void> createProject(Project project);
  Future<void> updateProject(Project project);
  Future<void> deleteProject(int id);
  Future<QuickSearchResponse> quickSearch(String query);
}