// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timestamps_local_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimestampsLocalModelAdapter extends TypeAdapter<TimestampsLocalModel> {
  @override
  final int typeId = 8;

  @override
  TimestampsLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimestampsLocalModel(
      createdAt: fields[0] as String?,
      updatedAt: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TimestampsLocalModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.createdAt)
      ..writeByte(1)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimestampsLocalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
