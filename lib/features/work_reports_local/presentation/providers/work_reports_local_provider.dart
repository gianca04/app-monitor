import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:monitor/features/work_reports_local/domain/entities/work_report_local_entity.dart';
import '../../data/datasources/work_reports_local_datasource.dart';
import '../../data/models/work_report_local_model.dart';
import '../../data/repositories/work_reports_local_repository_impl.dart';
import '../../domain/repositories/work_reports_local_repository.dart';
import '../../domain/usecases/create_work_report_local_usecase.dart';
import '../../domain/usecases/delete_work_report_local_usecase.dart';
import '../../domain/usecases/get_all_work_reports_local_usecase.dart';
import '../../domain/usecases/get_work_report_local_usecase.dart';
import '../../domain/usecases/update_work_report_local_usecase.dart';
import '../../domain/usecases/sync_work_report_local_usecase.dart';
import '../../domain/usecases/sync_all_work_reports_local_usecase.dart';
import '../../domain/usecases/get_unsynced_work_reports_local_usecase.dart';
import '../../../work_reports/presentation/providers/work_reports_provider.dart';
import '../../../work_report_photos_local/presentation/providers/work_report_photos_local_provider.dart';

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
    final localDataSource = ref.watch(workReportsLocalDataSourceProvider);
    final remoteDataSource = ref.watch(workReportsDataSourceProvider);
    final photosLocalDataSource = ref.watch(workReportPhotosLocalDataSourceProvider);
    return WorkReportsLocalRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      photosLocalDataSource: photosLocalDataSource,
    );
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

// Sync Use Cases Providers
final syncWorkReportLocalUseCaseProvider =
    Provider<SyncWorkReportLocalUseCase>((ref) {
      final repository = ref.watch(workReportsLocalRepositoryProvider);
      return SyncWorkReportLocalUseCase(repository);
    });

final syncAllWorkReportsLocalUseCaseProvider =
    Provider<SyncAllWorkReportsLocalUseCase>((ref) {
      final repository = ref.watch(workReportsLocalRepositoryProvider);
      return SyncAllWorkReportsLocalUseCase(repository);
    });

final getUnsyncedWorkReportsLocalUseCaseProvider =
    Provider<GetUnsyncedWorkReportsLocalUseCase>((ref) {
      final repository = ref.watch(workReportsLocalRepositoryProvider);
      return GetUnsyncedWorkReportsLocalUseCase(repository);
    });

// Count Provider
final workReportsLocalCountProvider = FutureProvider<int>((ref) async {
  final getAllUseCase = ref.watch(getAllWorkReportsLocalUseCaseProvider);
  final result = await getAllUseCase();

  return result.fold((failure) => 0, (reports) => reports.length);
});

// Unsynced Count Provider
final unsyncedWorkReportsLocalCountProvider = FutureProvider<int>((ref) async {
  final getUnsyncedUseCase = ref.watch(getUnsyncedWorkReportsLocalUseCaseProvider);
  final result = await getUnsyncedUseCase();

  return result.fold((failure) => 0, (reports) => reports.length);
});

// Work Reports List State Notifier
class WorkReportsLocalListNotifier extends StateNotifier<AsyncValue<List<WorkReportLocalEntity>>> {
  final GetAllWorkReportsLocalUseCase _getAllUseCase;
  final SyncAllWorkReportsLocalUseCase _syncAllUseCase;

  WorkReportsLocalListNotifier(this._getAllUseCase, this._syncAllUseCase)
      : super(const AsyncValue.loading()) {
    _loadReports();
  }

  Future<void> _loadReports() async {
    state = const AsyncValue.loading();
    try {
      final result = await _getAllUseCase();
      state = result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (reports) => AsyncValue.data(reports),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    await _loadReports();
  }

  Future<Map<String, dynamic>?> syncAll() async {
    try {
      final result = await _syncAllUseCase();
      return result.fold(
        (failure) => throw failure,
        (stats) {
          // Refresh the list after sync
          _loadReports();
          return stats;
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}

// Work Reports List Provider
final workReportsLocalListProvider = StateNotifierProvider<WorkReportsLocalListNotifier, AsyncValue<List<WorkReportLocalEntity>>>((ref) {
  final getAllUseCase = ref.watch(getAllWorkReportsLocalUseCaseProvider);
  final syncAllUseCase = ref.watch(syncAllWorkReportsLocalUseCaseProvider);
  return WorkReportsLocalListNotifier(getAllUseCase, syncAllUseCase);
});
