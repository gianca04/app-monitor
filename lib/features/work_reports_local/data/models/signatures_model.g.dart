// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signatures_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SignaturesModelAdapter extends TypeAdapter<SignaturesModel> {
  @override
  final int typeId = 7;

  @override
  SignaturesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SignaturesModel(
      supervisorSignature: fields[0] as String?,
      managerSignature: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SignaturesModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.supervisorSignature)
      ..writeByte(1)
      ..write(obj.managerSignature);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignaturesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
