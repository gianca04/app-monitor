// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_report_photo_local_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkReportPhotoLocalModelAdapter
    extends TypeAdapter<WorkReportPhotoLocalModel> {
  @override
  final int typeId = 9;

  @override
  WorkReportPhotoLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkReportPhotoLocalModel(
      id: fields[0] as int?,
      workReportId: fields[1] as int,
      photoPath: fields[2] as String?,
      beforeWorkPhotoPath: fields[3] as String?,
      descripcion: fields[4] as String?,
      beforeWorkDescripcion: fields[5] as String?,
      createdAt: fields[6] as String?,
      updatedAt: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkReportPhotoLocalModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workReportId)
      ..writeByte(2)
      ..write(obj.photoPath)
      ..writeByte(3)
      ..write(obj.beforeWorkPhotoPath)
      ..writeByte(4)
      ..write(obj.descripcion)
      ..writeByte(5)
      ..write(obj.beforeWorkDescripcion)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkReportPhotoLocalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
