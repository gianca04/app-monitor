// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resources_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResourcesModelAdapter extends TypeAdapter<ResourcesModel> {
  @override
  final int typeId = 6;

  @override
  ResourcesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResourcesModel(
      tools: fields[0] as String?,
      personnel: fields[1] as String?,
      materials: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ResourcesModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.tools)
      ..writeByte(1)
      ..write(obj.personnel)
      ..writeByte(2)
      ..write(obj.materials);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourcesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
