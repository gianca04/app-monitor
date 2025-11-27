import '../repositories/employees_repository.dart';
import '../../data/models/quick_search_response.dart';

class QuickSearchEmployeesUsecase {
  final EmployeesRepository repository;

  QuickSearchEmployeesUsecase(this.repository);

  Future<QuickSearchResponse> call(String query) async {
    return await repository.quickSearch(query);
  }
}