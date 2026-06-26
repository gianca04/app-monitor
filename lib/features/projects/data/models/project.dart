class Project {
  final int? id;
  final String? name;
  final String? startDate;
  final String? endDate;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int? quoteId;
  final int? subClientId;
  final String? clientName;
  final String? subClientName;
  final int? reportsCount;

  Project({
    this.id,
    this.name,
    this.startDate,
    this.endDate,
    this.location,
    this.latitude,
    this.longitude,
    this.quoteId,
    this.subClientId,
    this.clientName,
    this.subClientName,
    this.reportsCount,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int?,
      name: json['name'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      location: json['location'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      quoteId: json['quote_id'] as int?,
      subClientId: json['sub_client_id'] as int? ?? (json['sub_client'] != null ? json['sub_client']['id'] as int? : null),
      clientName: json['client'] != null ? json['client']['business_name'] as String? : null,
      subClientName: json['sub_client'] != null ? json['sub_client']['name'] as String? : null,
      reportsCount: json['reports_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'quote_id': quoteId,
      'sub_client_id': subClientId,
      'client_name': clientName,
      'sub_client_name': subClientName,
      'reports_count': reportsCount,
    };
  }

  Project copyWith({
    int? id,
    String? name,
    String? startDate,
    String? endDate,
    String? location,
    double? latitude,
    double? longitude,
    int? quoteId,
    int? subClientId,
    String? clientName,
    String? subClientName,
    int? reportsCount,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      quoteId: quoteId ?? this.quoteId,
      subClientId: subClientId ?? this.subClientId,
      clientName: clientName ?? this.clientName,
      subClientName: subClientName ?? this.subClientName,
      reportsCount: reportsCount ?? this.reportsCount,
    );
  }
}