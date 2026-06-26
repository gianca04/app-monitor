import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:monitor/core/constants/api_constants.dart';

abstract class WorkReportPdfDataSource {
  Future<File> downloadWorkReportPdf(int workReportId);
}

class WorkReportPdfDataSourceImpl implements WorkReportPdfDataSource {
  final Dio dio;

  WorkReportPdfDataSourceImpl(this.dio);

  @override
  Future<File> downloadWorkReportPdf(int workReportId) async {
    try {
      final filename = 'reporte_trabajo_$workReportId.pdf';
      
      // Lista de directorios a intentar (en orden de preferencia)
      final directoriesToTry = <String>[];
      
      if (Platform.isAndroid) {
        directoriesToTry.add('/storage/emulated/0/Download');
      }
      
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          directoriesToTry.add(downloadsDir.path);
        }
      } catch (_) {}
      
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        directoriesToTry.add(documentsDir.path);
      } catch (_) {}

      // Intentar descargar en el primer directorio que funcione
      for (final dirPath in directoriesToTry) {
        try {
          final dir = Directory(dirPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          
          final file = File('$dirPath/$filename');
          final response = await dio.download(
            '${ApiConstants.baseUrl}${ApiConstants.workReportPdfEndpoint}/$workReportId/pdf',
            file.path,
            options: Options(
              headers: {
                'Accept': 'application/pdf',
              },
            ),
          );

          if (response.statusCode == 200) {
            // print('📄 [PDF] Archivo guardado con éxito en: ${file.path}');
            return file;
          }
        } catch (e) {
          // print('⚠️ [PDF] Falló descarga en $dirPath: $e');
          // Continuar al siguiente directorio
        }
      }
      
      throw Exception('No se pudo guardar el archivo PDF en ningún directorio disponible.');
    } on DioException catch (e) {
      // print('❌ [PDF] Error DioException: ${e.message}');
      if (e.response != null) {
        // print('❌ [PDF] Response status: ${e.response?.statusCode}');
        // print('❌ [PDF] Response data: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      // print('❌ [PDF] Error inesperado: $e');
      rethrow;
    }
  }
}
