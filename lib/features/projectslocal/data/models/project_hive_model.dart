import 'package:hive/hive.dart';

import '../../domain/entities/project_entity.dart';

part 'project_hive_model.g.dart'; // Generado por build_runner

@HiveType(typeId: 0) // Asegúrate de que el typeId sea único
class ProjectHiveModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  ProjectHiveModel({required this.id, required this.name});

  // Mapper para convertir desde JSON (lo que viene de Laravel)
  factory ProjectHiveModel.fromJson(Map<String, dynamic> json) {
    return ProjectHiveModel(
      id: json['id'],
      name: json['name'],
    );
  }

  // Mapper hacia Entidad de Dominio (Clean Arch)
  ProjectEntity toEntity() {
    return ProjectEntity(id: id, name: name);
  }
}