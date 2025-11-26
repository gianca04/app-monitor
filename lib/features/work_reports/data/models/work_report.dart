import '../../../photos/data/models/photo.dart';

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
  final Employee employee;
  final Project project;
  final List<Photo> photos;
  final Summary summary;

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
    required this.employee,
    required this.project,
    required this.photos,
    required this.summary,
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
      employee: Employee.fromJson(json['employee']),
      project: Project.fromJson(json['project']),
      photos: (json['photos'] as List).map((e) => Photo.fromJson(e)).toList(),
      summary: Summary.fromJson(json['summary']),
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
      'employee': employee.toJson(),
      'project': project.toJson(),
      'photos': photos.map((e) => e.toJson()).toList(),
      'summary': summary.toJson(),
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
    Employee? employee,
    Project? project,
    List<Photo>? photos,
    Summary? summary,
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
      employee: employee ?? this.employee,
      project: project ?? this.project,
      photos: photos ?? this.photos,
      summary: summary ?? this.summary,
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

class Employee {
  final int id;
  final String documentType;
  final String documentNumber;
  final String firstName;
  final String lastName;
  final String fullName;
  final Position position;

  Employee({
    required this.id,
    required this.documentType,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.position,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      documentType: json['documentType'],
      documentNumber: json['documentNumber'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      fullName: json['fullName'],
      position: Position.fromJson(json['position']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'position': position.toJson(),
    };
  }
}

class Position {
  final int id;
  final String name;

  Position({
    required this.id,
    required this.name,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Project {
  final int id;
  final String name;
  final Location location;
  final Dates dates;
  final String status;
  final SubClient? subClient;
  final dynamic client;

  Project({
    required this.id,
    required this.name,
    required this.location,
    required this.dates,
    required this.status,
    this.subClient,
    this.client,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      location: Location.fromJson(json['location']),
      dates: Dates.fromJson(json['dates']),
      status: json['status'],
      subClient: json['subClient'] != null ? SubClient.fromJson(json['subClient']) : null,
      client: json['client'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location.toJson(),
      'dates': dates.toJson(),
      'status': status,
      'subClient': subClient?.toJson(),
      'client': client,
    };
  }
}

class Location {
  final double? latitude;
  final double? longitude;
  final String coordinates;

  Location({
    this.latitude,
    this.longitude,
    required this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'],
      longitude: json['longitude'],
      coordinates: json['coordinates'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'coordinates': coordinates,
    };
  }
}

class Dates {
  final String? startDate;
  final String? endDate;

  Dates({
    this.startDate,
    this.endDate,
  });

  factory Dates.fromJson(Map<String, dynamic> json) {
    return Dates(
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

class SubClient {
  final int id;
  final String name;

  SubClient({
    required this.id,
    required this.name,
  });

  factory SubClient.fromJson(Map<String, dynamic> json) {
    return SubClient(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Summary {
  final bool hasPhotos;
  final int photosCount;
  final bool hasSignatures;

  Summary({
    required this.hasPhotos,
    required this.photosCount,
    required this.hasSignatures,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      hasPhotos: json['hasPhotos'],
      photosCount: json['photosCount'],
      hasSignatures: json['hasSignatures'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasPhotos': hasPhotos,
      'photosCount': photosCount,
      'hasSignatures': hasSignatures,
    };
  }
}