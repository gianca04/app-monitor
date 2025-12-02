import 'package:hive/hive.dart';
import '../../domain/entities/work_report_photo_local_entity.dart';

part 'work_report_photo_local_model.g.dart';

@HiveType(typeId: 9)
class WorkReportPhotoLocalModel extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  final int workReportId;

  @HiveField(2)
  final String? photoPath;

  @HiveField(3)
  final String? beforeWorkPhotoPath;

  @HiveField(4)
  final String? descripcion;

  @HiveField(5)
  final String? beforeWorkDescripcion;

  @HiveField(6)
  final String? createdAt;

  @HiveField(7)
  final String? updatedAt;

  WorkReportPhotoLocalModel({
    this.id,
    required this.workReportId,
    this.photoPath,
    this.beforeWorkPhotoPath,
    this.descripcion,
    this.beforeWorkDescripcion,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from Entity
  factory WorkReportPhotoLocalModel.fromEntity(
    WorkReportPhotoLocalEntity entity,
  ) {
    return WorkReportPhotoLocalModel(
      id: entity.id,
      workReportId: entity.workReportId,
      photoPath: entity.photoPath,
      beforeWorkPhotoPath: entity.beforeWorkPhotoPath,
      descripcion: entity.descripcion,
      beforeWorkDescripcion: entity.beforeWorkDescripcion,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // Convert to Entity
  WorkReportPhotoLocalEntity toEntity() {
    return WorkReportPhotoLocalEntity(
      id: id,
      workReportId: workReportId,
      photoPath: photoPath,
      beforeWorkPhotoPath: beforeWorkPhotoPath,
      descripcion: descripcion,
      beforeWorkDescripcion: beforeWorkDescripcion,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
