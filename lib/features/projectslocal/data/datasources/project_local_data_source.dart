import 'package:hive/hive.dart';

import '../models/project_hive_model.dart';

abstract class ProjectLocalDataSource {
  Future<void> cacheProject(ProjectHiveModel project);
  Future<void> deleteProject(int id);
  String? getLastSyncTime();
  Future<void> saveLastSyncTime(String timestamp);
}

class ProjectLocalDataSourceImpl implements ProjectLocalDataSource {
  final Box<ProjectHiveModel> projectBox;
  final Box settingsBox; // Una caja pequeña para guardar fechas de config

  ProjectLocalDataSourceImpl({required this.projectBox, required this.settingsBox});

  @override
  Future<void> cacheProject(ProjectHiveModel project) async {
    // Usamos 'put' con el ID como key.
    // Si existe, lo actualiza. Si no existe, lo crea. (Upsert)
    await projectBox.put(project.id, project);
  }

  @override
  Future<void> deleteProject(int id) async {
    await projectBox.delete(id);
  }

  @override
  String? getLastSyncTime() {
    return settingsBox.get('last_sync_at');
  }

  @override
  Future<void> saveLastSyncTime(String timestamp) async {
    await settingsBox.put('last_sync_at', timestamp);
  }
}