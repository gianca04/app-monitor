import '../../domain/entities/paginated_positions.dart';
import '../../domain/repositories/position_repository.dart';
import '../datasources/position_datasource.dart';

class PositionRepositoryImpl implements PositionRepository {
  final PositionDataSource dataSource;

  PositionRepositoryImpl(this.dataSource);

  @override
  Future<PaginatedPositions> getPositions({
    String? search,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  }) async {
    final model = await dataSource.getPositions(
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
      perPage: perPage,
      page: page,
    );
    return PaginatedPositions(
      data: model.data,
      currentPage: model.currentPage,
      lastPage: model.lastPage,
      perPage: model.perPage,
      total: model.total,
      from: model.from,
      to: model.to,
    );
  }
}