import '../../data/models/position.dart';

abstract class PositionRepository {
  Future<List<Position>> getPositions();
  Future<Position?> getPosition(int id);
  Future<void> savePosition(Position position);
  Future<void> deletePosition(int id);
  Future<int> getNextId();
}