import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Signature PNG to Base64 and API POST Test', () async {
    // 1. Ruta del archivo PNG
    final file = File('C:/Users/gianca04/Documents/SAT_INDUSTRIALES_PROYECTOS/app-monitor/signature.png');
    
    // Verificar que existe
    expect(await file.exists(), isTrue, reason: 'El archivo signature.png no existe en la ruta especificada.');

    // 2. Leer archivo y convertir a Base64
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);
    final dataUri = 'data:image/png;base64,$base64String';

    print('Base64 prefix correctly formed: ${dataUri.substring(0, 30)}...');
    print('Total Base64 length: ${dataUri.length}');

    // 3. Enviar a nuestro nuevo endpoint temporal en Laravel
    final uri = Uri.parse('http://169.254.83.107:8000/api/test-signature');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'signature': dataUri}),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // 4. Validar resultado
      expect(response.statusCode, 200, reason: 'El endpoint no retornó 200 OK');
      
      final jsonResponse = jsonDecode(response.body);
      expect(jsonResponse['success'], isTrue, reason: 'El endpoint indicó que el Base64 era inválido');
      
      print('Test completado con éxito!');
    } catch (e) {
      fail('La petición HTTP falló: $e');
    }
  });
}
