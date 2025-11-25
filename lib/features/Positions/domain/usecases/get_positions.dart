import '../entities/paginated_positions.dart';
import '../repositories/position_repository.dart';

class GetPositionsUseCase {
  final PositionRepository repository;

  GetPositionsUseCase(this.repository);

  Future<PaginatedPositions> call({
    String? search,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  }) {
    return repository.getPositions(
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
      perPage: perPage,
      page: page,
    );
  }
}