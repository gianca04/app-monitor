# Quill Converter Service

Servicio para convertir entre Quill Delta JSON y HTML, implementado siguiendo Clean Architecture.

## Estructura

```
lib/core/
├── domain/
│   ├── entities/
│   │   └── quill_conversion_result.dart
│   ├── repositories/
│   │   └── quill_converter_repository.dart
│   └── usecases/
│       └── quill_converter/
│           ├── convert_quill_to_html.dart
│           └── convert_html_to_quill.dart
├── data/
│   ├── datasources/
│   │   └── quill_converter_data_source.dart
│   └── repositories/
│       └── quill_converter_repository_impl.dart
└── services/
    └── quill_converter_providers.dart
```

## Uso

### 1. Convertir Quill Delta a HTML

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitor/core/services/quill_converter_providers.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convertQuillToHtml = ref.watch(convertQuillToHtmlProvider);
    
    // Ejemplo de Quill Delta JSON
    const quillJson = '''
    {
      "ops": [
        {"insert": "Hello "},
        {"insert": "World", "attributes": {"bold": true}},
        {"insert": "\\n"}
      ]
    }
    ''';
    
    // Usar el caso de uso
    final result = await convertQuillToHtml(quillJson);
    
    result.fold(
      (failure) => print('Error: ${failure.message}'),
      (conversionResult) => print('HTML: ${conversionResult.content}'),
    );
  }
}
```

### 2. Convertir HTML a Quill Delta

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitor/core/services/quill_converter_providers.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convertHtmlToQuill = ref.watch(convertHtmlToQuillProvider);
    
    // Ejemplo de HTML
    const html = '<p>Hello <strong>World</strong></p>';
    
    // Usar el caso de uso
    final result = await convertHtmlToQuill(html);
    
    result.fold(
      (failure) => print('Error: ${failure.message}'),
      (conversionResult) => print('Quill JSON: ${conversionResult.content}'),
    );
  }
}
```

## Características

- ✅ Conversión bidireccional entre Quill Delta y HTML
- ✅ Soporte para formato de texto: **negrita**, *cursiva*, <u>subrayado</u>, ~~tachado~~
- ✅ Soporte para encabezados (h1-h6)
- ✅ Soporte para listas (ordenadas y no ordenadas)
- ✅ Manejo de errores con Either de dartz
- ✅ Implementación siguiendo Clean Architecture
- ✅ Inyección de dependencias con Riverpod

## Dependencias

- `fleather: ^1.17.0` - Para manipular documentos Quill
- `dartz: ^0.10.1` - Para manejo funcional de errores
- `equatable: ^2.0.5` - Para comparación de entidades
- `flutter_riverpod: ^2.5.1` - Para inyección de dependencias

## Capas de Clean Architecture

### Domain Layer
- **Entities**: `QuillConversionResult` - Entidad que representa el resultado de la conversión
- **Repositories**: `QuillConverterRepository` - Contrato abstracto del repositorio
- **Use Cases**: 
  - `ConvertQuillToHtml` - Caso de uso para convertir Quill a HTML
  - `ConvertHtmlToQuill` - Caso de uso para convertir HTML a Quill

### Data Layer
- **Data Sources**: `QuillConverterDataSource` - Maneja las conversiones usando Fleather
- **Repository Implementation**: `QuillConverterRepositoryImpl` - Implementación concreta del repositorio

### Presentation Layer
- **Providers**: Configuración de Riverpod para inyección de dependencias
