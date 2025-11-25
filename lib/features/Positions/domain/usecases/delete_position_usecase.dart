import '../repositories/position_repository.dart';

class DeletePositionUseCase {
  final PositionRepository repository;

  DeletePositionUseCase(this.repository);

  Future<void> call(int id) {
    return repository.deletePosition(id);
  }
}