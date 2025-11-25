import '../repositories/position_repository.dart';

class GetNextPositionIdUseCase {
  final PositionRepository repository;

  GetNextPositionIdUseCase(this.repository);

  Future<int> call() {
    return repository.getNextId();
  }
}