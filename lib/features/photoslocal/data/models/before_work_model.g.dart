// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'before_work_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BeforeWorkModelAdapter extends TypeAdapter<BeforeWorkModel> {
  @override
  final int typeId = 2;

  @override
  BeforeWorkModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BeforeWorkModel.yes;
      case 1:
        return BeforeWorkModel.no;
      default:
        return BeforeWorkModel.yes;
    }
  }

  @override
  void write(BinaryWriter writer, BeforeWorkModel obj) {
    switch (obj) {
      case BeforeWorkModel.yes:
        writer.writeByte(0);
        break;
      case BeforeWorkModel.no:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeforeWorkModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
