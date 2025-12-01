import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_local_data_source.dart';
import '../datasources/project_remote_data_source.dart';
import '../models/project_hive_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource remoteDataSource;
  final ProjectLocalDataSource localDataSource;

  ProjectRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, void>> syncProjects() async {
    try {
      // 1. Obtener la fecha de la última sincro desde Hive
      final lastSync = localDataSource.getLastSyncTime();

      // 2. Pedir a Laravel solo los cambios (Delta)
      // La respuesta incluye data nueva, editada y borrada (soft deleted)
      final response = await remoteDataSource.getProjectsDiff(lastSync);

      // 3. Procesar la lista
      for (var item in response.data) { // item es un Map<String, dynamic>

        // A. Verificar si el registro fue borrado en el servidor
        if (item['deleted_at'] != null) {
          // Si tiene fecha de borrado, lo eliminamos de Hive
          await localDataSource.deleteProject(item['id']);
        }
        // B. Si no está borrado, es nuevo o editado
        else {
          // Convertimos JSON a Modelo Hive (Solo extrae ID y Name)
          final projectModel = ProjectHiveModel.fromJson(item);
          // Guardamos en Hive (Upsert: inserta o actualiza automáticamente)
          await localDataSource.cacheProject(projectModel);
        }
      }

      // 4. Guardar el nuevo timestamp que nos envió Laravel en 'meta'
      // Esto es crucial para la próxima vez
      if (response.meta['current_sync_at'] != null) {
        await localDataSource.saveLastSyncTime(response.meta['current_sync_at']);
      }

      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}