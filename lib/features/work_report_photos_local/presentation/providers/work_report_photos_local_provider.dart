import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/datasources/work_report_photos_local_datasource.dart';
import '../../data/models/work_report_photo_local_model.dart';
import '../../data/repositories/work_report_photos_local_repository_impl.dart';
import '../../domain/repositories/work_report_photos_local_repository.dart';
import '../../domain/usecases/create_work_report_photo_local_usecase.dart';
import '../../domain/usecases/delete_work_report_photo_local_usecase.dart';
import '../../domain/usecases/get_photos_by_work_report_local_usecase.dart';
import '../../domain/usecases/update_work_report_photo_local_usecase.dart';

// Hive Box Provider
final workReportPhotosLocalBoxProvider =
    Provider<Box<WorkReportPhotoLocalModel>>((ref) {
      return Hive.box<WorkReportPhotoLocalModel>('work_report_photos_local');
    });

// Data Source Provider
final workReportPhotosLocalDataSourceProvider =
    Provider<WorkReportPhotosLocalDataSource>((ref) {
      final box = ref.watch(workReportPhotosLocalBoxProvider);
      return WorkReportPhotosLocalDataSourceImpl(photosBox: box);
    });

// Repository Provider
final workReportPhotosLocalRepositoryProvider =
    Provider<WorkReportPhotosLocalRepository>((ref) {
      final dataSource = ref.watch(workReportPhotosLocalDataSourceProvider);
      return WorkReportPhotosLocalRepositoryImpl(localDataSource: dataSource);
    });

// Use Cases Providers
final createWorkReportPhotoLocalUseCaseProvider =
    Provider<CreateWorkReportPhotoLocalUseCase>((ref) {
      final repository = ref.watch(workReportPhotosLocalRepositoryProvider);
      return CreateWorkReportPhotoLocalUseCase(repository);
    });

final getPhotosByWorkReportLocalUseCaseProvider =
    Provider<GetPhotosByWorkReportLocalUseCase>((ref) {
      final repository = ref.watch(workReportPhotosLocalRepositoryProvider);
      return GetPhotosByWorkReportLocalUseCase(repository);
    });

final updateWorkReportPhotoLocalUseCaseProvider =
    Provider<UpdateWorkReportPhotoLocalUseCase>((ref) {
      final repository = ref.watch(workReportPhotosLocalRepositoryProvider);
      return UpdateWorkReportPhotoLocalUseCase(repository);
    });

final deleteWorkReportPhotoLocalUseCaseProvider =
    Provider<DeleteWorkReportPhotoLocalUseCase>((ref) {
      final repository = ref.watch(workReportPhotosLocalRepositoryProvider);
      return DeleteWorkReportPhotoLocalUseCase(repository);
    });
