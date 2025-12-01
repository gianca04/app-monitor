// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'after_work_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AfterWorkModelAdapter extends TypeAdapter<AfterWorkModel> {
  @override
  final int typeId = 1;

  @override
  AfterWorkModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AfterWorkModel.yes;
      case 1:
        return AfterWorkModel.no;
      default:
        return AfterWorkModel.yes;
    }
  }

  @override
  void write(BinaryWriter writer, AfterWorkModel obj) {
    switch (obj) {
      case AfterWorkModel.yes:
        writer.writeByte(0);
        break;
      case AfterWorkModel.no:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AfterWorkModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
