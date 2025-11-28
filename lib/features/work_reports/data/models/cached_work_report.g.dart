// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_work_report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedWorkReportAdapter extends TypeAdapter<CachedWorkReport> {
  @override
  final int typeId = 0;

  @override
  CachedWorkReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedWorkReport(
      id: fields[0] as int,
      jsonString: fields[1] as String,
      isPending: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CachedWorkReport obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.jsonString)
      ..writeByte(2)
      ..write(obj.isPending);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedWorkReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
