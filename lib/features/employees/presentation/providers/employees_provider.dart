import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_employees_usecase.dart';
import '../../domain/usecases/quick_search_employees_usecase.dart';
import '../../data/models/employee.dart';
import '../../data/models/quick_search_response.dart';
import '../../data/datasources/employees_datasource_impl.dart';
import '../../data/repositories/employees_repository_impl.dart';

// Providers para dependencias
final employeesDataSourceProvider = Provider((ref) => EmployeesDatasourceImpl(ref.watch(dioProvider))); // Need to add dio
final employeesRepositoryProvider = Provider((ref) => EmployeesRepositoryImpl(ref.watch(employeesDataSourceProvider)));
final getEmployeesUseCaseProvider = Provider((ref) => GetEmployeesUsecase(ref.watch(employeesRepositoryProvider)));
final quickSearchEmployeesUseCaseProvider = Provider((ref) => QuickSearchEmployeesUsecase(ref.watch(employeesRepositoryProvider)));

// Assuming dioProvider is available, like in work_reports
final dioProvider = Provider((ref) => Dio());

// Estado para la lista
class EmployeesState {
  final List<Employee> employees;
  final bool isLoading;
  final String? error;

  EmployeesState({
    this.employees = const [],
    this.isLoading = false,
    this.error,
  });

  EmployeesState copyWith({
    List<Employee>? employees,
    bool? isLoading,
    String? error,
  }) {
    return EmployeesState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class EmployeesNotifier extends StateNotifier<EmployeesState> {
  final GetEmployeesUsecase getEmployeesUseCase;

  EmployeesNotifier(this.getEmployeesUseCase) : super(EmployeesState()) {
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final employees = await getEmployeesUseCase();
      state = state.copyWith(isLoading: false, employees: employees);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Estado para la búsqueda rápida
class QuickSearchState {
  final List<EmployeeQuick> results;
  final bool isLoading;
  final String? error;

  QuickSearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  QuickSearchState copyWith({
    List<EmployeeQuick>? results,
    bool? isLoading,
    String? error,
  }) {
    return QuickSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class QuickSearchNotifier extends StateNotifier<QuickSearchState> {
  final QuickSearchEmployeesUsecase quickSearchUseCase;

  QuickSearchNotifier(this.quickSearchUseCase) : super(QuickSearchState());

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = QuickSearchState();
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await quickSearchUseCase(query);
      state = state.copyWith(isLoading: false, results: response.data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final employeesProvider = StateNotifierProvider<EmployeesNotifier, EmployeesState>((ref) {
  final getUseCase = ref.watch(getEmployeesUseCaseProvider);
  return EmployeesNotifier(getUseCase);
});

final quickSearchProvider = StateNotifierProvider<QuickSearchNotifier, QuickSearchState>((ref) {
  final useCase = ref.watch(quickSearchEmployeesUseCaseProvider);
  return QuickSearchNotifier(useCase);
});