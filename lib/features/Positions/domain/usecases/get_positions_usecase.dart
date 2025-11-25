import '../repositories/position_repository.dart';
import '../../data/models/position.dart';

class GetPositionsUseCase {
  final PositionRepository repository;

  GetPositionsUseCase(this.repository);

  Future<List<Position>> call() {
    return repository.getPositions();
  }
}