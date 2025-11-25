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
  final PaginatedPositions? positions;
  final String? error;
  final String? search;
  final String? sortBy;
  final String? sortOrder;
  final int? perPage;
  final int? currentPage;

  PositionsListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.positions,
    this.error,
    this.search,
    this.sortBy = 'name',
    this.sortOrder = 'asc',
    this.perPage = 15,
    this.currentPage = 1,
  });

  PositionsListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    PaginatedPositions? positions,
    String? error,
    String? search,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    int? currentPage,
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
    );
  }

  bool get hasMorePages => positions != null && currentPage! < positions!.lastPage;
  bool get hasData => positions != null && positions!.data.isNotEmpty;
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

  Future<void> loadMorePositions() async {
    if (state.isLoadingMore || !state.hasMorePages) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage! + 1;
      final newPositions = await getPositionsUseCase(
        search: state.search,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        perPage: state.perPage,
        page: nextPage,
      );

      // Combinar los datos existentes con los nuevos
      final combinedData = [...state.positions!.data, ...newPositions.data];
      final updatedPositions = PaginatedPositions(
        data: combinedData,
        currentPage: newPositions.currentPage,
        lastPage: newPositions.lastPage,
        perPage: newPositions.perPage,
        total: newPositions.total,
        from: newPositions.from,
        to: newPositions.to,
      );

      state = state.copyWith(
        isLoadingMore: false,
        positions: updatedPositions,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void setSearch(String? search) {
    state = state.copyWith(search: search, currentPage: 1);
    loadPositions();
  }

  void setSort(String sortBy, String sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder, currentPage: 1);
    loadPositions();
  }

  void setPerPage(int perPage) {
    state = state.copyWith(perPage: perPage, currentPage: 1);
    loadPositions();
  }
}

final positionsListProvider = StateNotifierProvider<PositionsListNotifier, PositionsListState>((ref) {
  return PositionsListNotifier(ref.watch(getPositionsUseCaseProvider));
});