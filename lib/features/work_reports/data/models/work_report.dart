class WorkReport {
  final int? id;
  final String title;
  final String description;
  final DateTime date;
  final String status;

  WorkReport({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
  });

  factory WorkReport.fromJson(Map<String, dynamic> json) {
    return WorkReport(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'status': status,
    };
  }

  WorkReport copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    String? status,
  }) {
    return WorkReport(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }
}