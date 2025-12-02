class WorkReportLocalEntity {
  final int? id;
  final int employeeId;
  final int projectId;
  final String name;
  final String? description;
  /// Ruta del archivo de imagen de la firma del supervisor
  final String? supervisorSignature;
  /// Ruta del archivo de imagen de la firma del gerente
  final String? managerSignature;
  final String? suggestions;
  final String? createdAt;
  final String? updatedAt;
  final String? tools;
  final String? personnel;
  final String? materials;
  final String? startTime;
  final String? endTime;
  final bool isSynced;
  final int? syncedServerId;
  final String? syncError;
  final String? lastSyncAttempt;

  WorkReportLocalEntity({
    this.id,
    required this.employeeId,
    required this.projectId,
    required this.name,
    this.description,
    this.supervisorSignature,
    this.managerSignature,
    this.suggestions,
    this.createdAt,
    this.updatedAt,
    this.tools,
    this.personnel,
    this.materials,
    this.startTime,
    this.endTime,
    this.isSynced = false,
    this.syncedServerId,
    this.syncError,
    this.lastSyncAttempt,
  });

  WorkReportLocalEntity copyWith({
    int? id,
    int? employeeId,
    int? projectId,
    String? name,
    String? description,
    String? supervisorSignature,
    String? managerSignature,
    String? suggestions,
    String? createdAt,
    String? updatedAt,
    String? tools,
    String? personnel,
    String? materials,
    String? startTime,
    String? endTime,
    bool? isSynced,
    int? syncedServerId,
    String? syncError,
    String? lastSyncAttempt,
  }) {
    return WorkReportLocalEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      supervisorSignature: supervisorSignature ?? this.supervisorSignature,
      managerSignature: managerSignature ?? this.managerSignature,
      suggestions: suggestions ?? this.suggestions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tools: tools ?? this.tools,
      personnel: personnel ?? this.personnel,
      materials: materials ?? this.materials,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isSynced: isSynced ?? this.isSynced,
      syncedServerId: syncedServerId ?? this.syncedServerId,
      syncError: syncError ?? this.syncError,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }
}
