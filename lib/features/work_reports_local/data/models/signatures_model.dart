import 'package:hive/hive.dart';

part 'signatures_model.g.dart';

@HiveType(typeId: 7)
class SignaturesModel extends HiveObject {
  @HiveField(0)
  final String? supervisorSignature;

  @HiveField(1)
  final String? managerSignature;

  SignaturesModel({this.supervisorSignature, this.managerSignature});
}
