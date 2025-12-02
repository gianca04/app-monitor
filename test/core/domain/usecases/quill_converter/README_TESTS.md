# Pruebas Unitarias - Quill Converter Use Cases

## Resumen

Se han implementado pruebas unitarias completas para ambos casos de uso del servicio de conversión Quill ↔ HTML.

## Estructura de Pruebas

```
test/core/domain/usecases/quill_converter/
├── convert_quill_to_html_test.dart    # 6 tests
└── convert_html_to_quill_test.dart    # 8 tests
```

**Total: 14 pruebas unitarias** ✅

## Ejecución de Pruebas

```bash
# Ejecutar todas las pruebas del conversor
flutter test test/core/domain/usecases/quill_converter/

# Ejecutar pruebas específicas
flutter test test/core/domain/usecases/quill_converter/convert_quill_to_html_test.dart
flutter test test/core/domain/usecases/quill_converter/convert_html_to_quill_test.dart
```

## Cobertura de Pruebas

### convert_quill_to_html_test.dart

**Casos de prueba:**

1. ✅ **Conversión exitosa** - Verifica que se devuelva HTML correctamente
2. ✅ **JSON vacío** - Verifica manejo de error con entrada vacía
3. ✅ **Llamada al repositorio** - Verifica que se llame al método del repositorio
4. ✅ **Tipo de contenido** - Verifica que el resultado sea String no vacío
5. ✅ **JSON complejo** - Verifica manejo de Quill Delta con múltiples atributos
6. ✅ **Estructura de resultado** - Verifica que se devuelva QuillConversionResult

### convert_html_to_quill_test.dart

**Casos de prueba:**

1. ✅ **Conversión exitosa** - Verifica que se devuelva Quill Delta JSON correctamente
2. ✅ **HTML vacío** - Verifica manejo de error con entrada vacía
3. ✅ **Llamada al repositorio** - Verifica que se llame al método del repositorio
4. ✅ **JSON válido** - Verifica que el resultado contenga la estructura "ops"
5. ✅ **HTML complejo** - Verifica manejo de HTML con múltiples etiquetas y listas
6. ✅ **Texto plano** - Verifica conversión de HTML simple
7. ✅ **Etiquetas anidadas** - Verifica manejo de tags HTML anidados
8. ✅ **Saltos de línea** - Verifica manejo de `<br>` tags

## Patrones de Prueba Utilizados

### Mock Repository
Se implementó un `MockQuillConverterRepository` que simula el comportamiento del repositorio real:

```dart
class MockQuillConverterRepository implements QuillConverterRepository {
  @override
  Future<Either<Failure, QuillConversionResult>> convertQuillToHtml(
    String quillDeltaJson,
  ) async {
    if (quillDeltaJson.isEmpty) {
      return Left(ServerFailure('Invalid Quill Delta JSON'));
    }
    return Right(QuillConversionResult(content: '<p>Test HTML</p>'));
  }

  @override
  Future<Either<Failure, QuillConversionResult>> convertHtmlToQuill(
    String html,
  ) async {
    if (html.isEmpty) {
      return Left(ServerFailure('Invalid HTML'));
    }
    return Right(QuillConversionResult(
      content: '{"ops":[{"insert":"Test\\n"}]}',
    ));
  }
}
```

### Estructura AAA (Arrange-Act-Assert)
Todas las pruebas siguen el patrón AAA:

```dart
test('should return QuillConversionResult when successful', () async {
  // Arrange (preparar)
  const input = '<p>Test</p>';
  
  // Act (ejecutar)
  final result = await useCase(input);
  
  // Assert (verificar)
  expect(result, isA<Right<Failure, QuillConversionResult>>());
});
```

## Verificaciones Clave

### ✅ Casos Exitosos
- Verifican que se devuelva `Right<Failure, QuillConversionResult>`
- Validan el contenido del resultado
- Confirman el tipo de dato correcto

### ✅ Casos de Error
- Verifican que se devuelva `Left<Failure, QuillConversionResult>`
- Validan el tipo de `Failure` (ServerFailure)
- Confirman mensajes de error apropiados

### ✅ Casos de Integración
- Verifican llamadas al repositorio
- Validan el flujo completo del caso de uso
- Confirman comportamiento correcto con diferentes entradas

## Beneficios

1. **Cobertura completa** - Todos los flujos principales están probados
2. **Detección temprana de errores** - Las pruebas fallan si se rompe funcionalidad
3. **Documentación viva** - Las pruebas documentan el comportamiento esperado
4. **Refactoring seguro** - Permite modificar código con confianza
5. **Clean Architecture** - Pruebas aisladas de la capa de dominio

## Próximos Pasos (Opcional)

Para mayor cobertura, podrías agregar:

- Pruebas de integración del repositorio
- Pruebas del data source con datos reales de Fleather
- Pruebas de widgets para el ejemplo de UI
- Pruebas de golden tests para verificar HTML renderizado
