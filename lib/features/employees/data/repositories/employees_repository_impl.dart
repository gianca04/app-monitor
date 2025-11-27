import '../../domain/repositories/employees_repository.dart';
import '../datasources/employees_datasource_impl.dart';
import '../models/employee.dart';
import '../models/quick_search_response.dart';

class EmployeesRepositoryImpl implements EmployeesRepository {
  final EmployeesDatasourceImpl datasource;

  EmployeesRepositoryImpl(this.datasource);

  @override
  Future<List<Employee>> getEmployees() async {
    return await datasource.getEmployees();
  }

  @override
  Future<Employee?> getEmployee(int id) async {
    return await datasource.getEmployee(id);
  }

  @override
  Future<void> createEmployee(Employee employee) async {
    await datasource.createEmployee(employee);
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await datasource.updateEmployee(employee);
  }

  @override
  Future<void> deleteEmployee(int id) async {
    await datasource.deleteEmployee(id);
  }

  @override
  Future<QuickSearchResponse> quickSearch(String query) async {
    return await datasource.quickSearch(query);
  }
}