import 'package:hive/hive.dart';
import '../models/position.dart';

abstract class PositionLocalDataSource {
  Future<List<Position>> getPositions();
  Future<Position?> getPosition(int id);
  Future<void> savePosition(Position position);
  Future<void> deletePosition(int id);
  Future<int> getNextId();
}

class PositionLocalDataSourceImpl implements PositionLocalDataSource {
  static const String boxName = 'positions';
  static const String metaBoxName = 'metadata';

  @override
  Future<List<Position>> getPositions() async {
    final box = await Hive.openBox<Position>(boxName);
    return box.values.toList();
  }

  @override
  Future<Position?> getPosition(int id) async {
    final box = await Hive.openBox<Position>(boxName);
    return box.get(id);
  }

  @override
  Future<void> savePosition(Position position) async {
    final box = await Hive.openBox<Position>(boxName);
    await box.put(position.id, position);
  }

  @override
  Future<void> deletePosition(int id) async {
    final box = await Hive.openBox<Position>(boxName);
    await box.delete(id);
  }

  @override
  Future<int> getNextId() async {
    final metaBox = await Hive.openBox(metaBoxName);
    int nextId = metaBox.get('nextPositionId', defaultValue: 1);
    await metaBox.put('nextPositionId', nextId + 1);
    return nextId;
  }
}