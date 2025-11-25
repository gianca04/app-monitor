import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/position_local_datasource.dart';
import '../../data/repositories/position_repository_impl.dart';
import '../../domain/repositories/position_repository.dart';
import '../../domain/usecases/delete_position_usecase.dart';
import '../../domain/usecases/get_positions_usecase.dart';
import '../../domain/usecases/save_position_usecase.dart';
import '../../domain/usecases/get_next_position_id_usecase.dart';
import '../../data/models/position.dart';

// DataSource Provider
final positionLocalDataSourceProvider = Provider<PositionLocalDataSource>((ref) {
  return PositionLocalDataSourceImpl();
});

// Repository Provider
final positionRepositoryProvider = Provider<PositionRepository>((ref) {
  final dataSource = ref.watch(positionLocalDataSourceProvider);
  return PositionRepositoryImpl(dataSource);
});

// UseCases Providers
final getPositionsUseCaseProvider = Provider<GetPositionsUseCase>((ref) {
  final repository = ref.watch(positionRepositoryProvider);
  return GetPositionsUseCase(repository);
});

final savePositionUseCaseProvider = Provider<SavePositionUseCase>((ref) {
  final repository = ref.watch(positionRepositoryProvider);
  return SavePositionUseCase(repository);
});

final deletePositionUseCaseProvider = Provider<DeletePositionUseCase>((ref) {
  final repository = ref.watch(positionRepositoryProvider);
  return DeletePositionUseCase(repository);
});

final getNextPositionIdUseCaseProvider = Provider<GetNextPositionIdUseCase>((ref) {
  final repository = ref.watch(positionRepositoryProvider);
  return GetNextPositionIdUseCase(repository);
});

// Notifier for Positions
class PositionsNotifier extends Notifier<List<Position>> {
  @override
  List<Position> build() {
    // Initial state
    return [];
  }

  Future<void> loadPositions() async {
    final getPositions = ref.read(getPositionsUseCaseProvider);
    final positions = await getPositions();
    state = positions;
  }

  Future<void> addPosition(Position position) async {
    final usecase = ref.read(savePositionUseCaseProvider);
    await usecase(position);
    await loadPositions(); // Reload
  }

  Future<void> deletePosition(int id) async {
    final usecase = ref.read(deletePositionUseCaseProvider);
    await usecase(id);
    await loadPositions(); // Reload
  }
}

final positionsProvider = NotifierProvider<PositionsNotifier, List<Position>>(() {
  return PositionsNotifier();
});