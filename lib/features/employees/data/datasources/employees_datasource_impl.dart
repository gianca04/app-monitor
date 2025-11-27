import 'package:dio/dio.dart';
import 'employees_datasource.dart';
import '../models/employee.dart';
import '../models/quick_search_response.dart';
import 'package:monitor/core/constants/api_constants.dart';

class EmployeesDatasourceImpl implements EmployeesDatasource {
  final Dio dio;

  EmployeesDatasourceImpl(this.dio);

  @override
  Future<List<Employee>> getEmployees() async {
    // Placeholder implementation
    return [];
  }

  @override
  Future<Employee?> getEmployee(int id) async {
    // Placeholder implementation
    return null;
  }

  @override
  Future<void> createEmployee(Employee employee) async {
    // Placeholder implementation
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    // Placeholder implementation
  }

  @override
  Future<void> deleteEmployee(int id) async {
    // Placeholder implementation
  }

  @override
  Future<QuickSearchResponse> quickSearch(String query) async {
    final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.employeesEndpoint}/quick-search', queryParameters: {'query': query});
    return QuickSearchResponse.fromJson(response.data);
  }
}