import 'package:hive/hive.dart';

part 'signatures_model.g.dart';

/// Modelo para almacenar las firmas de supervisor y gerente
/// Las firmas se almacenan como rutas de archivos de imagen
@HiveType(typeId: 7)
class SignaturesModel extends HiveObject {
  /// Ruta del archivo de imagen de la firma del supervisor
  @HiveField(0)
  final String? supervisorSignature;

  /// Ruta del archivo de imagen de la firma del gerente
  @HiveField(1)
  final String? managerSignature;

  SignaturesModel({this.supervisorSignature, this.managerSignature});
}
