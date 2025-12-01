// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_local_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PhotoLocalModelAdapter extends TypeAdapter<PhotoLocalModel> {
  @override
  final int typeId = 4;

  @override
  PhotoLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhotoLocalModel(
      id: fields[0] as int?,
      workReportId: fields[1] as int,
      afterWork: fields[2] as AfterWorkModel,
      beforeWork: fields[3] as BeforeWorkModel,
      timestamps: fields[4] as TimestampsModel,
    );
  }

  @override
  void write(BinaryWriter writer, PhotoLocalModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workReportId)
      ..writeByte(2)
      ..write(obj.afterWork)
      ..writeByte(3)
      ..write(obj.beforeWork)
      ..writeByte(4)
      ..write(obj.timestamps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoLocalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
