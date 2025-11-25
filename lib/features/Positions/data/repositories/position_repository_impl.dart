import '../../domain/repositories/position_repository.dart';
import '../datasources/position_local_datasource.dart';
import '../models/position.dart';

class PositionRepositoryImpl implements PositionRepository {
  final PositionLocalDataSource localDataSource;

  PositionRepositoryImpl(this.localDataSource);

  @override
  Future<List<Position>> getPositions() {
    return localDataSource.getPositions();
  }

  @override
  Future<Position?> getPosition(int id) {
    return localDataSource.getPosition(id);
  }

  @override
  Future<void> savePosition(Position position) {
    return localDataSource.savePosition(position);
  }

  @override
  Future<void> deletePosition(int id) {
    return localDataSource.deletePosition(id);
  }

  @override
  Future<int> getNextId() {
    return localDataSource.getNextId();
  }
}