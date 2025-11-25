import 'position.dart';

class PaginatedPositions {
  final List<Position> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  PaginatedPositions({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  factory PaginatedPositions.fromJson(Map<String, dynamic> json) {
    return PaginatedPositions(
      data: (json['data'] as List).map((e) => Position.fromJson(e)).toList(),
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
      from: json['from'],
      to: json['to'],
    );
  }
}