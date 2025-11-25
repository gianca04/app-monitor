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
    return Photo(
      id: json['id'],
      workReportId: json['workReportId'],
      afterWork: AfterWork.fromJson(json['afterWork']),
      beforeWork: BeforeWork.fromJson(json['beforeWork']),
      timestamps: Timestamps.fromJson(json['timestamps']),
    );
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
  final String? photoUrl;
  final String description;

  AfterWork({
    this.photoUrl,
    required this.description,
  });

  factory AfterWork.fromJson(Map<String, dynamic> json) {
    return AfterWork(
      photoUrl: json['photoUrl'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoUrl': photoUrl,
      'description': description,
    };
  }
}

class BeforeWork {
  final String? photoUrl;
  final String description;

  BeforeWork({
    this.photoUrl,
    required this.description,
  });

  factory BeforeWork.fromJson(Map<String, dynamic> json) {
    return BeforeWork(
      photoUrl: json['photoUrl'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoUrl': photoUrl,
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