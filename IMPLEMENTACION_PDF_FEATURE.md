# Feature: Descarga de PDF de Reportes de Trabajo

## 📋 Resumen de Implementación

Se ha creado un nuevo feature completo para la descarga de PDFs de reportes de trabajo, siguiendo la arquitectura Clean Architecture del proyecto.

## 🗂️ Estructura de Archivos Creados

```
lib/features/work_report_pdf/
├── data/
│   ├── datasources/
│   │   └── work_report_pdf_datasource.dart
│   └── repositories/
│       └── work_report_pdf_repository_impl.dart
├── domain/
│   ├── repositories/
│   │   └── work_report_pdf_repository.dart
│   └── usecases/
│       └── download_work_report_pdf_usecase.dart
└── presentation/
    └── providers/
        └── work_report_pdf_provider.dart
```

## ✅ Características Implementadas

### 1. **DataSource** (`work_report_pdf_datasource.dart`)
- Realiza peticiones HTTP autenticadas al endpoint `/work-reports/{id}/pdf`
- Utiliza Dio para la comunicación con el servidor
- Decodifica respuesta JSON con pdf_base64 y filename
- Convierte base64 a bytes binarios
- Guarda el PDF en el sistema de archivos local usando `path_provider`
- Manejo robusto de errores con logs detallados

### 2. **Repository** (`work_report_pdf_repository_impl.dart`)
- Implementa el contrato del dominio
- Delega la lógica al datasource
- Proporciona abstracción entre capas

### 3. **UseCase** (`download_work_report_pdf_usecase.dart`)
- Encapsula la lógica de negocio de descarga
- Interfaz simple: recibe ID del reporte, devuelve File

### 4. **Provider** (`work_report_pdf_provider.dart`)
- Gestiona el estado de descarga con Riverpod
- Estado incluye: isDownloading, downloadedFile, error, progress
- Diferencia tipos de errores (red, servidor, sistema de archivos)
- Proporciona métodos: downloadPdf, clearError, reset

### 5. **Integración en UI** (`work_report_view_screen.dart`)
- Botón de descarga añadido al AppBar
- Diálogo de progreso durante descarga
- Diálogo de éxito con opciones: Cerrar o Abrir PDF
- Manejo de errores con SnackBar
- Integración con `open_file` para abrir PDF en visor nativo

## 📦 Dependencias Añadidas

```yaml
open_file: ^3.5.9  # Para abrir archivos PDF con el visor nativo
```

## 🔄 Flujo de Funcionamiento

1. **Usuario** presiona botón de descarga en vista de reporte
2. **Sistema** muestra diálogo "Descargando PDF..."
3. **Petición HTTP** GET autenticada a `/work-reports/{id}/pdf`
4. **Servidor** responde con JSON: `{data: {pdf_base64, filename}}`
5. **Decodificación** de base64 a bytes
6. **Guardado** en directorio de documentos de la app
7. **Notificación** al usuario con ruta del archivo
8. **Opción** de abrir inmediatamente con visor nativo

## 🛡️ Manejo de Errores

- **Error de conexión**: "Error de conexión. Verifica tu conexión a internet."
- **Error del servidor**: "Error del servidor. Inténtalo más tarde."
- **Error de sistema de archivos**: "Error inesperado al descargar el PDF."

## 📱 Ubicación de Archivos

### Android
```
/data/user/0/{package_name}/app_flutter/reporte_{id}.pdf
```

### iOS
```
/var/mobile/Containers/Data/Application/{UUID}/Documents/reporte_{id}.pdf
```

## 📊 Diagrama de Proceso

Se creó el diagrama PlantUML: `diagrama_work_report_pdf_download.puml`

## 📝 Documentación

Se añadió la sección completa del feature en: `DOCUMENTACION_FEATURES.md`

## 🚀 Próximos Pasos

1. Ejecutar `flutter pub get` para instalar la nueva dependencia `open_file`
2. Probar la funcionalidad con un reporte existente
3. Verificar que el servidor devuelva el formato JSON correcto:
   ```json
   {
     "data": {
       "pdf_base64": "JVBERi0xLjQK...",
       "filename": "reporte_123.pdf"
     }
   }
   ```

## 🔧 Personalización Adicional (Opcional)

Puedes extender el feature con:
- Barra de progreso detallada para PDFs grandes
- Lista de PDFs descargados previamente
- Opción de compartir PDF vía otras apps
- Eliminación de PDFs antiguos para liberar espacio
- Descarga en segundo plano con notificaciones
- Previsualización rápida antes de descargar completo
