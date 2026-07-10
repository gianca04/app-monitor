import '../repositories/projects_repository.dart';
import '../../data/models/projects_response.dart';

class GetProjectsUsecase {
  final ProjectsRepository repository;

  GetProjectsUsecase(this.repository);

  Future<ProjectsResponse> call({int page = 1, int perPage = 15}) async {
    return await repository.getProjects(page: page, perPage: perPage);
  }
}