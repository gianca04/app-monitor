import '../../domain/repositories/projects_repository.dart';
import '../datasources/projects_datasource_impl.dart';
import '../models/project.dart';
import '../models/quick_search_response.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsDatasourceImpl datasource;

  ProjectsRepositoryImpl(this.datasource);

  @override
  Future<List<Project>> getProjects() async {
    return await datasource.getProjects();
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