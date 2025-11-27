import 'work_report.dart';

class WorkReportsResponse {
  final bool? success;
  final String? message;
  final List<WorkReport>? data;
  final Pagination? pagination;
  final Filters? filters;
  final Meta? meta;

  WorkReportsResponse({
    this.success,
    this.message,
    this.data,
    this.pagination,
    this.filters,
    this.meta,
  });

  factory WorkReportsResponse.fromJson(Map<String, dynamic> json) {
    return WorkReportsResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: (json['data'] as List?)?.map((e) => WorkReport.fromJson(e)).toList(),
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      filters: json['filters'] != null ? Filters.fromJson(json['filters']) : null,
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((e) => e.toJson()).toList(),
      'pagination': pagination?.toJson(),
      'filters': filters?.toJson(),
      'meta': meta?.toJson(),
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

class Filters {
  final String? search;
  final String? status;
  final String? dateFrom;
  final String? dateTo;
  final int? employeeId;
  final int? projectId;
  final int? positionId;

  Filters({
    this.search,
    this.status,
    this.dateFrom,
    this.dateTo,
    this.employeeId,
    this.projectId,
    this.positionId,
  });

  factory Filters.fromJson(Map<String, dynamic> json) {
    return Filters(
      search: json['search'] as String?,
      status: json['status'] as String?,
      dateFrom: json['dateFrom'] as String?,
      dateTo: json['dateTo'] as String?,
      employeeId: json['employeeId'] as int?,
      projectId: json['projectId'] as int?,
      positionId: json['positionId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'status': status,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'employeeId': employeeId,
      'projectId': projectId,
      'positionId': positionId,
    };
  }
}

class Meta {
  final String? apiVersion;
  final String? timestamp;

  Meta({
    this.apiVersion,
    this.timestamp,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      apiVersion: json['apiVersion'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiVersion': apiVersion,
      'timestamp': timestamp,
    };
  }
}