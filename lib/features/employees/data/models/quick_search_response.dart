class EmployeeQuick {
  final int? id;
  final String? fullName;
  final String? documentNumber;
  final String? position;

  EmployeeQuick({this.id, this.fullName, this.documentNumber, this.position});

  factory EmployeeQuick.fromJson(Map<String, dynamic> json) {
    return EmployeeQuick(
      id: json['id'] as int?,
      fullName: json['full_name'] as String?,
      documentNumber: json['document_number'] as String?,
      position: json['position'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'document_number': documentNumber,
      'position': position,
    };
  }
}

class QuickSearchResponse {
  final bool success;
  final String message;
  final List<EmployeeQuick> data;
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
      data: (json['data'] as List)
          .map((e) => EmployeeQuick.fromJson(e))
          .toList(),
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}
