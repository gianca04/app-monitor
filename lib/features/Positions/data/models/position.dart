import 'package:hive/hive.dart';

part 'position.g.dart';

@HiveType(typeId: 0)
class Position {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;

  const Position({
    required this.id,
    required this.name,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  Position copyWith({
    int? id,
    String? name,
  }) {
    return Position(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'Position(id: $id, name: $name)';
}