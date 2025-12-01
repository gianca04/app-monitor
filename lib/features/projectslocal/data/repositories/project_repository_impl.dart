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
      bool hasMore = true;

      while (hasMore) {
        // 1. Obtener la fecha de la última sincro desde Hive
        final lastSync = localDataSource.getLastSyncTime();

        // 2. Pedir a Laravel solo los cambios (Delta)
        final response = await remoteDataSource.getProjectsDiff(lastSync);

        // 3. Procesar los deletes
        if (response.data.delete.isNotEmpty) {
          for (var item in response.data.delete) {
            await localDataSource.deleteProject(item['id']);
          }
        }

        // 4. Procesar los upserts
        if (response.data.upsert.isNotEmpty) {
          for (var item in response.data.upsert) {
            final projectModel = ProjectHiveModel.fromJson(item);
            await localDataSource.cacheProject(projectModel);
          }
        }

        // 5. Guardar el next_sync_token
        await localDataSource.saveLastSyncTime(response.syncInfo.nextSyncToken);

        // 6. Decidir si continuar
        hasMore = response.syncInfo.hasMore;
      }

      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}