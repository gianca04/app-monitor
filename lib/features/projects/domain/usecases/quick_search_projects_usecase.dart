import '../repositories/projects_repository.dart';
import '../../data/models/quick_search_response.dart';

class QuickSearchProjectsUsecase {
  final ProjectsRepository repository;

  QuickSearchProjectsUsecase(this.repository);

  Future<QuickSearchResponse> call(String query) async {
    return await repository.quickSearch(query);
  }
}