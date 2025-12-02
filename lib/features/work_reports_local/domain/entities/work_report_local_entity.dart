class WorkReportLocalEntity {
  final int? id;
  final int employeeId;
  final int projectId;
  final String name;
  final String? description;
  final String? supervisorSignature;
  final String? managerSignature;
  final String? suggestions;
  final String? createdAt;
  final String? updatedAt;
  final String? tools;
  final String? personnel;
  final String? materials;
  final String? startTime;
  final String? endTime;

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
    );
  }
}
