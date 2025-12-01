// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timestamps_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimestampsModelAdapter extends TypeAdapter<TimestampsModel> {
  @override
  final int typeId = 3;

  @override
  TimestampsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimestampsModel(
      createdAt: fields[0] as DateTime,
      updatedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TimestampsModel obj) {
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
      other is TimestampsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
