import '../../data/models/employee.dart';
import '../../data/models/quick_search_response.dart';

abstract class EmployeesRepository {
  Future<List<Employee>> getEmployees();
  Future<Employee?> getEmployee(int id);
  Future<void> createEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(int id);
  Future<QuickSearchResponse> quickSearch(String query);
}