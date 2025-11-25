import '../repositories/position_repository.dart';
import '../../data/models/position.dart';

class SavePositionUseCase {
  final PositionRepository repository;

  SavePositionUseCase(this.repository);

  Future<void> call(Position position) {
    return repository.savePosition(position);
  }
}