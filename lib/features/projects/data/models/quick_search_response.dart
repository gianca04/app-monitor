class ProjectQuick {
  final int? id;
  final String? name;

  ProjectQuick({
    this.id,
    this.name,
  });

  factory ProjectQuick.fromJson(Map<String, dynamic> json) {
    return ProjectQuick(
      id: json['id'] as int?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class QuickSearchResponse {
  final bool success;
  final String message;
  final List<ProjectQuick> data;
  final Map<String, dynamic>? meta;

  QuickSearchResponse({
    required this.success,
    required this.message,
    required this.data,
    this.meta,
  });

  factory QuickSearchResponse.fromJson(Map<String, dynamic> json) {
    return QuickSearchResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List).map((e) => ProjectQuick.fromJson(e)).toList(),
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}