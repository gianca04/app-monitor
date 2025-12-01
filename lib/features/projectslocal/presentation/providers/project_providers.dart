import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/project_local_data_source.dart';
import '../../data/datasources/project_remote_data_source.dart';
import '../../data/models/project_hive_model.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/repositories/project_repository.dart';

// Provider for projectBox
final projectBoxProvider = FutureProvider<Box<ProjectHiveModel>>((ref) async {
  return await Hive.openBox<ProjectHiveModel>('projects');
});

// Provider for settingsBox
final settingsBoxProvider = FutureProvider<Box>((ref) async {
  return await Hive.openBox('settings');
});

// Provider for ProjectLocalDataSource
final projectLocalDataSourceProvider = FutureProvider<ProjectLocalDataSource>((ref) async {
  final projectBox = await ref.watch(projectBoxProvider.future);
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return ProjectLocalDataSourceImpl(projectBox: projectBox, sharedPreferences: sharedPreferences);
});

// Provider for ProjectRemoteDataSource
final projectRemoteDataSourceProvider = Provider<ProjectRemoteDataSource>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return ProjectRemoteDataSourceImpl(dio: dio);
});

// Provider for ProjectRepository
final projectRepositoryProvider = FutureProvider<ProjectRepository>((ref) async {
  final localDataSource = await ref.watch(projectLocalDataSourceProvider.future);
  final remoteDataSource = ref.watch(projectRemoteDataSourceProvider);
  return ProjectRepositoryImpl(remoteDataSource: remoteDataSource, localDataSource: localDataSource);
});

// Provider para obtener la cantidad de proyectos locales
final projectsCountProvider = FutureProvider<int>((ref) async {
  final box = await ref.watch(projectBoxProvider.future);
  return box.length;
});

// Provider para obtener la última sincronización
final lastSyncProvider = FutureProvider<String?>((ref) async {
  final localDataSource = await ref.watch(projectLocalDataSourceProvider.future);
  final lastSync = localDataSource.getLastSyncTime();
  return lastSync;
});

// Provider para el estado de sincronización
final syncStateProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

class SyncState {
  final bool isLoading;
  final String? error;
  final bool success;

  SyncState({this.isLoading = false, this.error, this.success = false});

  SyncState copyWith({bool? isLoading, String? error, bool? success}) {
    return SyncState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref ref;

  SyncNotifier(this.ref) : super(SyncState());

  Future<void> syncProjects() async {
    state = state.copyWith(isLoading: true, error: null, success: false);

    try {
      final repository = await ref.read(projectRepositoryProvider.future);
      final result = await repository.syncProjects();

      result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure is ServerFailure ? failure.message : 'Error desconocido');
        },
        (_) {
          state = state.copyWith(isLoading: false, success: true);
          // Invalidar los providers para refrescar los datos
          ref.invalidate(projectsCountProvider);
          ref.invalidate(lastSyncProvider);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}