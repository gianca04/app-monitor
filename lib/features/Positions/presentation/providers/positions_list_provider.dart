import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/paginated_positions.dart';
import '../../domain/usecases/get_positions.dart';
import '../../data/datasources/position_datasource.dart';
import '../../data/repositories/position_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Providers para dependencias
final positionDataSourceProvider = Provider((ref) => PositionDataSourceImpl(ref.watch(authenticatedDioProvider)));
final positionRepositoryProvider = Provider((ref) => PositionRepositoryImpl(ref.watch(positionDataSourceProvider)));
final getPositionsUseCaseProvider = Provider((ref) => GetPositionsUseCase(ref.watch(positionRepositoryProvider)));

// Estado de la lista de posiciones
class PositionsListState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<Position> positions;
  final String? error;
  final String? search;
  final String? sortBy;
  final String? sortOrder;
  final int? perPage;
  final int currentPage;
  final bool hasMorePages;
  final int total;

  PositionsListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.positions = const [],
    this.error,
    this.search,
    this.sortBy = 'name',
    this.sortOrder = 'asc',
    this.perPage = 15,
    this.currentPage = 1,
    this.hasMorePages = true,
    this.total = 0,
  });

  PositionsListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<Position>? positions,
    String? error,
    String? search,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? currentPage,
    bool? hasMorePages,
    int? total,
  }) {
    return PositionsListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      positions: positions ?? this.positions,
      error: error ?? this.error,
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      perPage: perPage ?? this.perPage,
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      total: total ?? this.total,
    );
  }
}

class PositionsListNotifier extends StateNotifier<PositionsListState> {
  final GetPositionsUseCase getPositionsUseCase;

  PositionsListNotifier(this.getPositionsUseCase) : super(PositionsListState()) {
    loadPositions();
  }

  Future<void> loadPositions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final positions = await getPositionsUseCase(
        search: state.search,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        perPage: state.perPage,
        page: state.currentPage,
      );
      state = state.copyWith(isLoading: false, positions: positions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String? search) {
    state = state.copyWith(search: search);
    loadPositions();
  }

  void setSort(String sortBy, String sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    loadPositions();
  }

  void setPerPage(int perPage) {
    state = state.copyWith(perPage: perPage, currentPage: 1);
    loadPositions();
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
    loadPositions();
  }
}

final positionsListProvider = StateNotifierProvider<PositionsListNotifier, PositionsListState>((ref) {
  return PositionsListNotifier(ref.watch(getPositionsUseCaseProvider));
});