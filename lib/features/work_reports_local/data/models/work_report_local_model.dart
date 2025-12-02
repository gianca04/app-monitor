import 'package:hive/hive.dart';
import '../../domain/entities/work_report_local_entity.dart';
import 'resources_model.dart';
import 'signatures_model.dart';
import 'timestamps_local_model.dart';

part 'work_report_local_model.g.dart';

@HiveType(typeId: 5)
class WorkReportLocalModel extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  final int employeeId;

  @HiveField(2)
  final int projectId;

  @HiveField(3)
  final String name;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final ResourcesModel? resources;

  @HiveField(6)
  final SignaturesModel? signatures;

  @HiveField(7)
  final String? suggestions;

  @HiveField(8)
  final TimestampsLocalModel? timestamps;

  @HiveField(9)
  final String? startTime;

  @HiveField(10)
  final String? endTime;

  WorkReportLocalModel({
    this.id,
    required this.employeeId,
    required this.projectId,
    required this.name,
    this.description,
    this.resources,
    this.signatures,
    this.suggestions,
    this.timestamps,
    this.startTime,
    this.endTime,
  });

  // Convert from Domain Entity
  factory WorkReportLocalModel.fromEntity(WorkReportLocalEntity entity) {
    return WorkReportLocalModel(
      id: entity.id,
      employeeId: entity.employeeId,
      projectId: entity.projectId,
      name: entity.name,
      description: entity.description,
      resources: ResourcesModel(
        tools: entity.tools,
        personnel: entity.personnel,
        materials: entity.materials,
      ),
      signatures: SignaturesModel(
        supervisorSignature: entity.supervisorSignature,
        managerSignature: entity.managerSignature,
      ),
      suggestions: entity.suggestions,
      timestamps: TimestampsLocalModel(
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      ),
      startTime: entity.startTime,
      endTime: entity.endTime,
    );
  }

  // Convert to Domain Entity
  WorkReportLocalEntity toEntity() {
    return WorkReportLocalEntity(
      id: id,
      employeeId: employeeId,
      projectId: projectId,
      name: name,
      description: description,
      supervisorSignature: signatures?.supervisorSignature,
      managerSignature: signatures?.managerSignature,
      suggestions: suggestions,
      createdAt: timestamps?.createdAt,
      updatedAt: timestamps?.updatedAt,
      tools: resources?.tools,
      personnel: resources?.personnel,
      materials: resources?.materials,
      startTime: startTime,
      endTime: endTime,
    );
  }
}
