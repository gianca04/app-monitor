class WorkReportPhotoLocalEntity {
  final int? id;
  final int workReportId;
  final String? photoPath;
  final String? beforeWorkPhotoPath;
  final String? descripcion;
  final String? beforeWorkDescripcion;
  final String? createdAt;
  final String? updatedAt;

  const WorkReportPhotoLocalEntity({
    this.id,
    required this.workReportId,
    this.photoPath,
    this.beforeWorkPhotoPath,
    this.descripcion,
    this.beforeWorkDescripcion,
    this.createdAt,
    this.updatedAt,
  });
}
