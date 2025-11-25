class WorkReport {
  final int? id;
  final String name;
  final String description;
  final String reportDate;
  final String? startTime;
  final String? endTime;
  final Resources resources;
  final String suggestions;
  final Signatures signatures;
  final Timestamps timestamps;

  WorkReport({
    this.id,
    required this.name,
    required this.description,
    required this.reportDate,
    this.startTime,
    this.endTime,
    required this.resources,
    required this.suggestions,
    required this.signatures,
    required this.timestamps,
  });

  factory WorkReport.fromJson(Map<String, dynamic> json) {
    return WorkReport(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      reportDate: json['reportDate'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      resources: Resources.fromJson(json['resources']),
      suggestions: json['suggestions'],
      signatures: Signatures.fromJson(json['signatures']),
      timestamps: Timestamps.fromJson(json['timestamps']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'reportDate': reportDate,
      'startTime': startTime,
      'endTime': endTime,
      'resources': resources.toJson(),
      'suggestions': suggestions,
      'signatures': signatures.toJson(),
      'timestamps': timestamps.toJson(),
    };
  }

  WorkReport copyWith({
    int? id,
    String? name,
    String? description,
    String? reportDate,
    String? startTime,
    String? endTime,
    Resources? resources,
    String? suggestions,
    Signatures? signatures,
    Timestamps? timestamps,
  }) {
    return WorkReport(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      reportDate: reportDate ?? this.reportDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      resources: resources ?? this.resources,
      suggestions: suggestions ?? this.suggestions,
      signatures: signatures ?? this.signatures,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}

class Resources {
  final String tools;
  final String personnel;
  final String materials;

  Resources({
    required this.tools,
    required this.personnel,
    required this.materials,
  });

  factory Resources.fromJson(Map<String, dynamic> json) {
    return Resources(
      tools: json['tools'],
      personnel: json['personnel'],
      materials: json['materials'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tools': tools,
      'personnel': personnel,
      'materials': materials,
    };
  }
}

class Signatures {
  final String? supervisor;
  final String? manager;

  Signatures({
    this.supervisor,
    this.manager,
  });

  factory Signatures.fromJson(Map<String, dynamic> json) {
    return Signatures(
      supervisor: json['supervisor'],
      manager: json['manager'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supervisor': supervisor,
      'manager': manager,
    };
  }
}

class Timestamps {
  final String createdAt;
  final String updatedAt;

  Timestamps({
    required this.createdAt,
    required this.updatedAt,
  });

  factory Timestamps.fromJson(Map<String, dynamic> json) {
    return Timestamps(
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}