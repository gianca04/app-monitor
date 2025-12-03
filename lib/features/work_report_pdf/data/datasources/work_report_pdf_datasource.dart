import 'dart:convert';
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
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.workReportsEndpoint}/$workReportId/pdf',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        final base64Pdf = jsonData['data']['pdf_base64'] as String;
        final filename = jsonData['data']['filename'] as String;

        // Decodificar base64 a bytes
        final bytes = base64Decode(base64Pdf);

        // Guardar en el directorio de documentos de la aplicación
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(bytes);

        print('📄 [PDF] Archivo guardado: ${file.path}');
        return file;
      } else {
        throw Exception('Error al descargar PDF: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [PDF] Error DioException: ${e.message}');
      if (e.response != null) {
        print('❌ [PDF] Response status: ${e.response?.statusCode}');
        print('❌ [PDF] Response data: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      print('❌ [PDF] Error inesperado: $e');
      rethrow;
    }
  }
}
