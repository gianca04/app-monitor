import 'project.dart';

class ProjectsResponse {
  final bool? success;
  final List<Project>? data;
  final Pagination? pagination;
  final String? message;

  ProjectsResponse({
    this.success,
    this.data,
    this.pagination,
    this.message,
  });

  factory ProjectsResponse.fromJson(Map<String, dynamic> json) {
    return ProjectsResponse(
      success: json['success'] as bool?,
      data: json['data'] != null
          ? (json['data'] as List).map((i) => Project.fromJson(i as Map<String, dynamic>)).toList()
          : null,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.map((e) => e.toJson()).toList(),
      'pagination': pagination?.toJson(),
      'message': message,
    };
  }
}

class Pagination {
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? lastPage;
  final int? from;
  final int? to;
  final bool? hasMorePages;

  Pagination({
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
    this.from,
    this.to,
    this.hasMorePages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int?,
      perPage: json['perPage'] as int?,
      currentPage: json['currentPage'] as int?,
      lastPage: json['lastPage'] as int?,
      from: json['from'] as int?,
      to: json['to'] as int?,
      hasMorePages: json['hasMorePages'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'perPage': perPage,
      'currentPage': currentPage,
      'lastPage': lastPage,
      'from': from,
      'to': to,
      'hasMorePages': hasMorePages,
    };
  }
}
