import '../repositories/employees_repository.dart';
import '../../data/models/employee.dart';

class GetEmployeesUsecase {
  final EmployeesRepository repository;

  GetEmployeesUsecase(this.repository);

  Future<List<Employee>> call() async {
    return await repository.getEmployees();
  }
}