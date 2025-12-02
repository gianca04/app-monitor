import 'package:hive/hive.dart';

part 'resources_model.g.dart';

@HiveType(typeId: 6)
class ResourcesModel extends HiveObject {
  @HiveField(0)
  final String? tools;

  @HiveField(1)
  final String? personnel;

  @HiveField(2)
  final String? materials;

  ResourcesModel({this.tools, this.personnel, this.materials});
}
