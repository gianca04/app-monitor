import '../../domain/repositories/projects_repository.dart';
import '../datasources/projects_datasource_impl.dart';
import '../models/project.dart';
import '../models/projects_response.dart';
import '../models/quick_search_response.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsDatasourceImpl datasource;

  ProjectsRepositoryImpl(this.datasource);

  @override
  Future<ProjectsResponse> getProjects({int page = 1, int perPage = 15}) async {
    return await datasource.getProjects(page: page, perPage: perPage);
  }

  @override
  Future<Project?> getProject(int id) async {
    return await datasource.getProject(id);
  }

  @override
  Future<void> createProject(Project project) async {
    await datasource.createProject(project);
  }

  @override
  Future<void> updateProject(Project project) async {
    await datasource.updateProject(project);
  }

  @override
  Future<void> deleteProject(int id) async {
    await datasource.deleteProject(id);
  }

  @override
  Future<QuickSearchResponse> quickSearch(String query) async {
    return await datasource.quickSearch(query);
  }
}