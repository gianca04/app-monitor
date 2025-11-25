import '../entities/paginated_positions.dart';

abstract class PositionRepository {
  Future<PaginatedPositions> getPositions({
    String? search,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  });
}