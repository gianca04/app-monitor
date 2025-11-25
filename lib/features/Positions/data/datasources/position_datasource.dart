import 'package:dio/dio.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/paginated_positions.dart';
import 'package:monitor/core/constants/api_constants.dart';

abstract class PositionDataSource {
  Future<PaginatedPositions> getPositions({
    String? search,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  });
}

class PositionDataSourceImpl implements PositionDataSource {
  final Dio dio;

  PositionDataSourceImpl(this.dio);

  @override
  Future<PaginatedPositions> getPositions({
    String? search,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? page,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (search != null) queryParameters['search'] = search;
    if (sortBy != null) queryParameters['sort_by'] = sortBy;
    if (sortOrder != null) queryParameters['sort_order'] = sortOrder;
    if (perPage != null) queryParameters['per_page'] = perPage;
    if (page != null) queryParameters['page'] = page;

    final response = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.positionsEndpoint}',
      queryParameters: queryParameters,
    );

    final json = response.data as Map<String, dynamic>;
    final pagination = json['pagination'] as Map<String, dynamic>;

    final data = (json['data'] as List).map((e) {
      final positionJson = e as Map<String, dynamic>;
      return Position(
        id: positionJson['id'],
        name: positionJson['name'],
        createdAt: positionJson['created_at'] != null ? DateTime.parse(positionJson['created_at']) : null,
        updatedAt: positionJson['updated_at'] != null ? DateTime.parse(positionJson['updated_at']) : null,
      );
    }).toList();

    return PaginatedPositions(
      data: data,
      currentPage: pagination['currentPage'],
      lastPage: pagination['lastPage'],
      perPage: pagination['perPage'],
      total: pagination['total'],
      from: pagination['from'],
      to: pagination['to'],
    );
  }
}