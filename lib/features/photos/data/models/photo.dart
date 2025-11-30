class Photo {
  final int? id;
  final int workReportId;
  final AfterWork afterWork;
  final BeforeWork beforeWork;
  final Timestamps timestamps;

  Photo({
    this.id,
    required this.workReportId,
    required this.afterWork,
    required this.beforeWork,
    required this.timestamps,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('afterWork')) {
      return Photo(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
        workReportId: json['workReportId'] is int ? json['workReportId'] : int.parse(json['workReportId'].toString()),
        afterWork: AfterWork.fromJson(json['afterWork']),
        beforeWork: BeforeWork.fromJson(json['beforeWork']),
        timestamps: Timestamps.fromJson(json['timestamps']),
      );
    } else {
      return Photo(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
        workReportId: json['work_report_id'] is int ? json['work_report_id'] : int.parse(json['work_report_id'].toString()),
        afterWork: AfterWork(
          photoPath: json['photo_path'],
          description: json['descripcion'],
        ),
        beforeWork: BeforeWork(
          photoPath: json['before_work_photo_path'],
          description: json['before_work_descripcion'],
        ),
        timestamps: Timestamps(
          createdAt: json['created_at'] ?? '',
          updatedAt: json['updated_at'] ?? '',
        ),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workReportId': workReportId,
      'afterWork': afterWork.toJson(),
      'beforeWork': beforeWork.toJson(),
      'timestamps': timestamps.toJson(),
    };
  }

  Photo copyWith({
    int? id,
    int? workReportId,
    AfterWork? afterWork,
    BeforeWork? beforeWork,
    Timestamps? timestamps,
  }) {
    return Photo(
      id: id ?? this.id,
      workReportId: workReportId ?? this.workReportId,
      afterWork: afterWork ?? this.afterWork,
      beforeWork: beforeWork ?? this.beforeWork,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}

class AfterWork {
  final String? photoPath;
  final String? description;

  AfterWork({
    this.photoPath,
    this.description,
  });

  factory AfterWork.fromJson(Map<String, dynamic> json) {
    return AfterWork(
      photoPath: json['photoPath'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoPath': photoPath,
      'description': description,
    };
  }
}

class BeforeWork {
  final String? photoPath;
  final String? description;

  BeforeWork({
    this.photoPath,
    this.description,
  });

  factory BeforeWork.fromJson(Map<String, dynamic> json) {
    return BeforeWork(
      photoPath: json['photoPath'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoPath': photoPath,
      'description': description,
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