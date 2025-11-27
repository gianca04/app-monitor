import '../repositories/projects_repository.dart';
import '../../data/models/project.dart';

class GetProjectsUsecase {
  final ProjectsRepository repository;

  GetProjectsUsecase(this.repository);

  Future<List<Project>> call() async {
    return await repository.getProjects();
  }
}