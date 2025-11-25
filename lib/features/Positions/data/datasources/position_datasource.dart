import 'package:dio/dio.dart';
import '../models/paginated_positions_model.dart';
import 'package:monitor/core/constants/api_constants.dart';

abstract class PositionDataSource {
  Future<PaginatedPositionsModel> getPositions({
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
  Future<PaginatedPositionsModel> getPositions({
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
    return PaginatedPositionsModel.fromJson(response.data);
  }
}