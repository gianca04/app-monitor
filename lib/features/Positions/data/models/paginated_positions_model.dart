import '../../domain/entities/paginated_positions.dart';
import 'position_model.dart';

class PaginatedPositionsModel extends PaginatedPositions {
  PaginatedPositionsModel({
    required super.data,
    required super.currentPage,
    required super.lastPage,
    required super.perPage,
    required super.total,
    super.from,
    super.to,
  });

  factory PaginatedPositionsModel.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    return PaginatedPositionsModel(
      data: (json['data'] as List).map((e) => PositionModel.fromJson(e)).toList(),
      currentPage: pagination['currentPage'],
      lastPage: pagination['lastPage'],
      perPage: pagination['perPage'],
      total: pagination['total'],
      from: pagination['from'],
      to: pagination['to'],
    );
  }
}