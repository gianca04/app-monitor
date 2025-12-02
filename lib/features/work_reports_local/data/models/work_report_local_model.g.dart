// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_report_local_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkReportLocalModelAdapter extends TypeAdapter<WorkReportLocalModel> {
  @override
  final int typeId = 5;

  @override
  WorkReportLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkReportLocalModel(
      id: fields[0] as int?,
      employeeId: fields[1] as int,
      projectId: fields[2] as int,
      name: fields[3] as String,
      description: fields[4] as String?,
      resources: fields[5] as ResourcesModel?,
      signatures: fields[6] as SignaturesModel?,
      suggestions: fields[7] as String?,
      timestamps: fields[8] as TimestampsLocalModel?,
      startTime: fields[9] as String?,
      endTime: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkReportLocalModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.employeeId)
      ..writeByte(2)
      ..write(obj.projectId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.resources)
      ..writeByte(6)
      ..write(obj.signatures)
      ..writeByte(7)
      ..write(obj.suggestions)
      ..writeByte(8)
      ..write(obj.timestamps)
      ..writeByte(9)
      ..write(obj.startTime)
      ..writeByte(10)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkReportLocalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
