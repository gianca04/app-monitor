import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../../core/error/failures.dart';
import '../../domain/entities/work_report_local_entity.dart';
import '../../domain/repositories/work_reports_local_repository.dart';
import '../datasources/work_reports_local_datasource.dart';
import '../models/work_report_local_model.dart';
import '../../../work_reports/data/datasources/work_reports_datasource.dart';
import '../../../work_report_photos_local/data/datasources/work_report_photos_local_datasource.dart';

class WorkReportsLocalRepositoryImpl implements WorkReportsLocalRepository {
  final WorkReportsLocalDataSource localDataSource;
  final WorkReportsDataSource remoteDataSource;
  final WorkReportPhotosLocalDataSource photosLocalDataSource;

  WorkReportsLocalRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.photosLocalDataSource,
  });

  @override
  Future<Either<Failure, int>> saveWorkReport(
    WorkReportLocalEntity report,
  ) async {
    try {
      final model = WorkReportLocalModel.fromEntity(report);
      final id = await localDataSource.saveWorkReport(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkReportLocalEntity>> getWorkReport(int id) async {
    try {
      final model = await localDataSource.getWorkReport(id);
      if (model == null) {
        return Left(CacheFailure('Work report with id $id not found'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkReportLocalEntity>>>
  getAllWorkReports() async {
    try {
      final models = await localDataSource.getAllWorkReports();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> updateWorkReport(
    WorkReportLocalEntity report,
  ) async {
    try {
      final model = WorkReportLocalModel.fromEntity(report);
      final id = await localDataSource.updateWorkReport(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWorkReport(int id) async {
    try {
      await localDataSource.deleteWorkReport(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkReportLocalEntity>>> getUnsyncedWorkReports() async {
    try {
      final models = await localDataSource.getUnsyncedWorkReports();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkReportLocalEntity>> syncWorkReport(int localId) async {
    try {
      // 1. Obtener el reporte local
      final localReport = await localDataSource.getWorkReport(localId);
      if (localReport == null) {
        return Left(CacheFailure('Reporte local no encontrado'));
      }

      // 2. Obtener las fotos locales asociadas
      final photosResult = await photosLocalDataSource.getPhotosByWorkReport(localId);
      final photos = <Map<String, dynamic>>[];

      for (var photo in photosResult) {
        final photoMap = <String, dynamic>{
          'descripcion': photo.descripcion ?? '',
          'before_work_descripcion': photo.beforeWorkDescripcion ?? '',
        };

        // Convertir rutas locales a MultipartFile si existen y son válidas
        if (photo.photoPath != null && photo.photoPath!.isNotEmpty) {
          try {
            final multipartFile = await _createMultipartFileFromPath(photo.photoPath!, 'photo_${photo.id}.jpg');
            if (multipartFile != null) {
              photoMap['photo'] = multipartFile;
              print('✅ [SYNC] Added photo for workReport $localId: ${photo.photoPath}');
            } else {
              print('⚠️ [SYNC] Could not create multipart file from path: ${photo.photoPath}');
            }
          } catch (e) {
            print('❌ [SYNC] Error processing photo path ${photo.photoPath}: $e');
          }
        }

        if (photo.beforeWorkPhotoPath != null && photo.beforeWorkPhotoPath!.isNotEmpty) {
          try {
            final multipartFile = await _createMultipartFileFromPath(photo.beforeWorkPhotoPath!, 'before_photo_${photo.id}.jpg');
            if (multipartFile != null) {
              photoMap['before_work_photo'] = multipartFile;
              print('✅ [SYNC] Added before_work_photo for workReport $localId: ${photo.beforeWorkPhotoPath}');
            } else {
              print('⚠️ [SYNC] Could not create multipart file from before_work path: ${photo.beforeWorkPhotoPath}');
            }
          } catch (e) {
            print('❌ [SYNC] Error processing before_work_photo path ${photo.beforeWorkPhotoPath}: $e');
          }
        }

        // Solo agregar la foto si tiene al menos una imagen o descripción
        if (photoMap.containsKey('photo') || photoMap.containsKey('before_work_photo') ||
            (photoMap['descripcion']?.isNotEmpty ?? false) ||
            (photoMap['before_work_descripcion']?.isNotEmpty ?? false)) {
          photos.add(photoMap);
        }
      }

      print('📸 [SYNC] Total photos to sync for workReport $localId: ${photos.length}');

      // 3. Sincronizar con el servidor
      final serverReport = await remoteDataSource.createWorkReport(
        localReport.projectId,
        localReport.employeeId,
        localReport.name,
        localReport.timestamps?.createdAt?.split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
        localReport.startTime,
        localReport.endTime,
        localReport.description,
        localReport.resources?.tools,
        localReport.resources?.personnel,
        localReport.resources?.materials,
        localReport.suggestions,
        localReport.signatures?.supervisorSignature,
        localReport.signatures?.managerSignature,
        photos,
      );

      // 4. Marcar como sincronizado
      await localDataSource.markAsSynced(localId, serverReport.id!);

      // 5. Retornar el reporte actualizado
      final updatedReport = await localDataSource.getWorkReport(localId);
      return Right(updatedReport!.toEntity());
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.response?.data?['error'] ?? e.message ?? 'Error de conexión';
      await localDataSource.markSyncError(localId, errorMsg);
      return Left(ServerFailure(errorMsg));
    } catch (e) {
      await localDataSource.markSyncError(localId, e.toString());
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> syncAllWorkReports() async {
    try {
      final unsyncedReports = await localDataSource.getUnsyncedWorkReports();
      
      int successCount = 0;
      int failureCount = 0;
      final errors = <String>[];

      for (var report in unsyncedReports) {
        if (report.id != null) {
          final result = await syncWorkReport(report.id!);
          result.fold(
            (failure) {
              failureCount++;
              errors.add('Reporte #${report.id}: ${failure.message}');
            },
            (_) => successCount++,
          );
        }
      }

      return Right({
        'total': unsyncedReports.length,
        'success': successCount,
        'failed': failureCount,
        'errors': errors,
      });
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<MultipartFile?> _createMultipartFileFromPath(String path, String filename) async {
    try {
      final file = File(path);

      // Verificar que el archivo existe
      if (!await file.exists()) {
        print('⚠️ [SYNC] File does not exist: $path');
        return null;
      }

      // Verificar que el archivo no esté vacío
      final length = await file.length();
      if (length == 0) {
        print('⚠️ [SYNC] File is empty: $path');
        return null;
      }

      // Verificar que sea un archivo de imagen válido (tamaño razonable)
      if (length > 50 * 1024 * 1024) { // 50MB máximo
        print('⚠️ [SYNC] File too large: $path ($length bytes)');
        return null;
      }

      final bytes = await file.readAsBytes();

      // Verificar que los bytes sean válidos
      if (bytes.isEmpty) {
        print('⚠️ [SYNC] Read empty bytes from file: $path');
        return null;
      }

      print('✅ [SYNC] Successfully read ${bytes.length} bytes from $path');
      return MultipartFile.fromBytes(bytes, filename: filename);
    } catch (e) {
      print('❌ [SYNC] Error creating MultipartFile from $path: $e');
      return null;
    }
  }
}
