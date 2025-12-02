import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/datasources/work_reports_local_datasource.dart';
import '../../data/models/work_report_local_model.dart';
import '../../data/repositories/work_reports_local_repository_impl.dart';
import '../../domain/repositories/work_reports_local_repository.dart';
import '../../domain/usecases/create_work_report_local_usecase.dart';
import '../../domain/usecases/delete_work_report_local_usecase.dart';
import '../../domain/usecases/get_all_work_reports_local_usecase.dart';
import '../../domain/usecases/get_work_report_local_usecase.dart';
import '../../domain/usecases/update_work_report_local_usecase.dart';

// Hive Box Provider
final workReportsLocalBoxProvider = Provider<Box<WorkReportLocalModel>>((ref) {
  return Hive.box<WorkReportLocalModel>('work_reports_local');
});

// Data Source Provider
final workReportsLocalDataSourceProvider = Provider<WorkReportsLocalDataSource>(
  (ref) {
    final box = ref.watch(workReportsLocalBoxProvider);
    return WorkReportsLocalDataSourceImpl(workReportsBox: box);
  },
);

// Repository Provider
final workReportsLocalRepositoryProvider = Provider<WorkReportsLocalRepository>(
  (ref) {
    final dataSource = ref.watch(workReportsLocalDataSourceProvider);
    return WorkReportsLocalRepositoryImpl(localDataSource: dataSource);
  },
);

// Use Cases Providers
final createWorkReportLocalUseCaseProvider =
    Provider<CreateWorkReportLocalUseCase>((ref) {
      final repository = ref.watch(workReportsLocalRepositoryProvider);
      return CreateWorkReportLocalUseCase(repository);
    });

final getWorkReportLocalUseCaseProvider = Provider<GetWorkReportLocalUseCase>((
  ref,
) {
  final repository = ref.watch(workReportsLocalRepositoryProvider);
  return GetWorkReportLocalUseCase(repository);
});

final getAllWorkReportsLocalUseCaseProvider =
    Provider<GetAllWorkReportsLocalUseCase>((ref) {
      final repository = ref.watch(workReportsLocalRepositoryProvider);
      return GetAllWorkReportsLocalUseCase(repository);
    });

final updateWorkReportLocalUseCaseProvider =
    Provider<UpdateWorkReportLocalUseCase>((ref) {
      final repository = ref.watch(workReportsLocalRepositoryProvider);
      return UpdateWorkReportLocalUseCase(repository);
    });

final deleteWorkReportLocalUseCaseProvider =
    Provider<DeleteWorkReportLocalUseCase>((ref) {
      final repository = ref.watch(workReportsLocalRepositoryProvider);
      return DeleteWorkReportLocalUseCase(repository);
    });

// Count Provider
final workReportsLocalCountProvider = FutureProvider<int>((ref) async {
  final getAllUseCase = ref.watch(getAllWorkReportsLocalUseCaseProvider);
  final result = await getAllUseCase();

  return result.fold((failure) => 0, (reports) => reports.length);
});
