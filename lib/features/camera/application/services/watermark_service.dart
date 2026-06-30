import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_service.dart';

/// Servicio de marca de agua optimizado usando dart:ui Canvas (GPU-acelerado).
/// Reemplaza el procesamiento lento con el paquete `image` (Dart puro, CPU).
class WatermarkService {
  // Caché del logo decodificado como ui.Image (se carga una sola vez)
  ui.Image? _cachedLogo;
  bool _logoLoadAttempted = false;
  bool _localeInitialized = false;

  // Caché de configuración de layout
  Map<String, double>? _cachedLayout;
  String? _cachedPhotosPath;

  /// Pre-carga el logo y la configuración. Llamar una vez al iniciar la cámara.
  Future<void> preload() async {
    await _ensureLogoLoaded();
    await _ensureLocaleInitialized();
    await _loadLayoutSettings();
  }

  /// Carga el logo desde assets y lo decodifica como ui.Image (nativo, rápido).
  Future<void> _ensureLogoLoaded() async {
    if (_logoLoadAttempted) return;
    _logoLoadAttempted = true;

    try {
      final logoData = await rootBundle.load('assets/images/png/Logo.png');
      final bytes = logoData.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _cachedLogo = frame.image;
      // debugPrint(
      //   '✅ Logo cacheado: ${_cachedLogo!.width}x${_cachedLogo!.height}',
      // );
    } catch (e) {
      // debugPrint('⚠️ Error cargando logo: $e');
    }
  }

  Future<void> _ensureLocaleInitialized() async {
    if (_localeInitialized) return;
    await initializeDateFormatting('es', null);
    _localeInitialized = true;
  }

  /// Carga la configuración de layout desde SharedPreferences (una sola vez).
  Future<void> _loadLayoutSettings() async {
    final prefs = await SharedPreferences.getInstance();

    String photosPath = prefs.getString('photos_path') ?? 'Por defecto';
    if (photosPath == 'Por defecto' || photosPath.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      photosPath = dir.path;
    }
    _cachedPhotosPath = photosPath;

    _cachedLayout = {
      'logo_x': prefs.getDouble('wm_logo_x') ?? 0.04888569730586374,
      'logo_y': prefs.getDouble('wm_logo_y') ?? 0.03871862040876778,
      'logo_scale': prefs.getDouble('wm_logo_scale') ?? 1.0,
      'time_x': prefs.getDouble('wm_time_x') ?? 0.04359275950871635,
      'time_y': prefs.getDouble('wm_time_y') ?? 0.8919667320793845,
      'time_scale': prefs.getDouble('wm_time_scale') ?? 1.0,
      'loc_x': prefs.getDouble('wm_location_x') ?? 0.04749281893819335,
      'loc_y': prefs.getDouble('wm_location_y') ?? 0.7902510367298579,
      'loc_scale': prefs.getDouble('wm_location_scale') ?? 1.1296037946428565,
    };
  }

  /// Recarga la configuración (llamar cuando el usuario cambie ajustes de marca de agua).
  Future<void> reloadSettings() async {
    _cachedLayout = null;
    _cachedPhotosPath = null;
    await _loadLayoutSettings();
  }

  /// Aplica la marca de agua a la imagen capturada usando dart:ui Canvas.
  Future<File?> addWatermark({
    required File imageFile,
    required double latitude,
    required double longitude,
    required String city,
  }) async {
    try {
      await _ensureLogoLoaded();
      await _ensureLocaleInitialized();
      if (_cachedLayout == null) await _loadLayoutSettings();

      final layout = _cachedLayout!;
      final savePath = _cachedPhotosPath!;

      // 1. Decodificar la imagen capturada con dart:ui (nativo, rápido)
      final imageBytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      // 2. Calcular recorte 3:4 centrado
      final isPortrait = originalImage.height > originalImage.width;
      final targetRatio = isPortrait ? (3.0 / 4.0) : (4.0 / 3.0);
      final currentRatio = originalImage.width / originalImage.height;

      int srcX = 0, srcY = 0;
      int srcWidth = originalImage.width, srcHeight = originalImage.height;

      if ((currentRatio - targetRatio).abs() > 0.01) {
        if (isPortrait) {
          if (currentRatio < targetRatio) {
            srcWidth = originalImage.width;
            srcHeight = (originalImage.width / targetRatio).round();
          } else {
            srcHeight = originalImage.height;
            srcWidth = (originalImage.height * targetRatio).round();
          }
        } else {
          if (currentRatio > targetRatio) {
            srcHeight = originalImage.height;
            srcWidth = (originalImage.height * targetRatio).round();
          } else {
            srcWidth = originalImage.width;
            srcHeight = (originalImage.width / targetRatio).round();
          }
        }
        srcX = ((originalImage.width - srcWidth) / 2).round();
        srcY = ((originalImage.height - srcHeight) / 2).round();
      }

      // 3. Crear Canvas y dibujar todo con aceleración GPU
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Dibujar la imagen recortada
      canvas.drawImageRect(
        originalImage,
        ui.Rect.fromLTWH(
          srcX.toDouble(),
          srcY.toDouble(),
          srcWidth.toDouble(),
          srcHeight.toDouble(),
        ),
        ui.Rect.fromLTWH(0, 0, srcWidth.toDouble(), srcHeight.toDouble()),
        ui.Paint(),
      );

      // Multiplicador global de escala (referencia: ancho 375px igual que la UI)
      final globalScale = srcWidth / 375.0;

      // 4. Dibujar Logo
      if (_cachedLogo != null) {
        final logoScale = layout['logo_scale']! * globalScale;
        final logoTargetWidth = (100 * logoScale).round(); // Base 100px
        final logoAspect = _cachedLogo!.width / _cachedLogo!.height;
        final logoTargetHeight = (logoTargetWidth / logoAspect).round();

        final logoX = layout['logo_x']! * srcWidth;
        final logoY = layout['logo_y']! * srcHeight;

        canvas.drawImageRect(
          _cachedLogo!,
          ui.Rect.fromLTWH(
            0,
            0,
            _cachedLogo!.width.toDouble(),
            _cachedLogo!.height.toDouble(),
          ),
          ui.Rect.fromLTWH(
            logoX,
            logoY,
            logoTargetWidth.toDouble(),
            logoTargetHeight.toDouble(),
          ),
          ui.Paint()..filterQuality = ui.FilterQuality.high,
        );
      }

      // 5. Dibujar Fecha y Hora
      final now = DateTime.now();
      final timeStr = DateFormat('HH:mm').format(now);
      final dateStr = DateFormat('dd/MM/yyyy').format(now);
      String dayStr = DateFormat('E', 'es').format(now);
      dayStr = dayStr.substring(0, 1).toUpperCase() + dayStr.substring(1);

      {
        final scale = layout['time_scale']! * globalScale;
        final posX = layout['time_x']! * srcWidth;
        final posY = layout['time_y']! * srcHeight;

        // Hora grande (Base 24)
        final timeFontSize = 24.0 * scale;
        final timeParagraph = _buildParagraph(
          timeStr,
          fontSize: timeFontSize,
          color: const ui.Color(0xFFFFFFFF),
          fontWeight: ui.FontWeight.w300,
        );
        canvas.drawParagraph(timeParagraph, ui.Offset(posX, posY));

        // Línea amber separadora (Base ancho 2, alto 20, padding 8)
        final timeWidth = timeParagraph.maxIntrinsicWidth;
        final lineX = posX + timeWidth + (8 * scale);
        final lineWidth = 2.0 * scale;
        final lineHeight = 20.0 * scale;
        // Ajuste en Y para centrar la línea
        canvas.drawRect(
          ui.Rect.fromLTWH(
            lineX,
            posY + (timeFontSize - lineHeight) / 2,
            lineWidth,
            lineHeight,
          ),
          ui.Paint()..color = const ui.Color(0xFFFFC107), // Amber
        );

        // Fecha y día (Base 8, padding 8)
        final dateFontSize = 8.0 * scale;
        final dateX = lineX + (8 * scale);

        final dateParagraph = _buildParagraph(
          dateStr,
          fontSize: dateFontSize,
          color: const ui.Color(0xFFFFFFFF),
        );
        canvas.drawParagraph(
          dateParagraph,
          ui.Offset(
            dateX,
            posY + (timeFontSize - (dateFontSize * 2 + 4 * scale)) / 2,
          ),
        );

        final dayParagraph = _buildParagraph(
          dayStr,
          fontSize: dateFontSize,
          color: const ui.Color(0xFFFFFFFF),
        );
        canvas.drawParagraph(
          dayParagraph,
          ui.Offset(
            dateX,
            posY +
                (timeFontSize - (dateFontSize * 2 + 4 * scale)) / 2 +
                dateFontSize +
                (4 * scale),
          ),
        );
      }

      // 6. Dibujar Ubicación
      {
        final scale = layout['loc_scale']! * globalScale;
        final posX = layout['loc_x']! * srcWidth;
        var posY = layout['loc_y']! * srcHeight;

        final cityFontSize = 10.0 * scale; // Base 10

        final cityParagraph = _buildParagraph(
          city, // Contiene nombre, calle y/o ciudad
          fontSize: cityFontSize,
          color: const ui.Color(0xFFFFFFFF),
          fontWeight: ui.FontWeight.bold,
        );
        canvas.drawParagraph(cityParagraph, ui.Offset(posX, posY));

        posY += cityFontSize + (2 * scale); // Base padding

        final coordinates = LocationService().currentCoordinates;
        if (coordinates.isNotEmpty) {
          final coordFontSize = 8.0 * scale; // Base 8 (como en live preview)
          final coordParagraph = _buildParagraph(
            coordinates,
            fontSize: coordFontSize,
            color: const ui.Color(0xFFFFFFFF),
          );
          canvas.drawParagraph(coordParagraph, ui.Offset(posX, posY));
          posY += coordFontSize + (2 * scale);
        }

        final empresaFontSize = 9.0 * scale; // Base 9

        final empresaParagraph = _buildParagraph(
          'SAT INDUSTRIALES',
          fontSize: empresaFontSize,
          color: const ui.Color(0xFFFFFFFF),
        );
        canvas.drawParagraph(empresaParagraph, ui.Offset(posX, posY));
      }

      // 7. Finalizar y exportar
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(srcWidth, srcHeight);
      final byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        // debugPrint('❌ Error: toByteData retornó null');
        return null;
      }

      // Guardar archivo
      final newFileName = 'SAT_${now.millisecondsSinceEpoch}.png';
      final newPath = '$savePath/$newFileName';
      final newFile = File(newPath);
      await newFile.create(recursive: true);
      await newFile.writeAsBytes(byteData.buffer.asUint8List());

      // debugPrint('✅ Foto con marca de agua guardada: $newPath');

      // Liberar recursos
      originalImage.dispose();
      finalImage.dispose();

      return newFile;
    } catch (e, st) {
      // debugPrint('❌ Error en watermark: $e');
      // debugPrint('$st');
      return null;
    }
  }

  /// Construye un ui.Paragraph con estilos personalizados.
  ui.Paragraph _buildParagraph(
    String text, {
    required double fontSize,
    ui.Color color = const ui.Color(0xFFFFFFFF),
    ui.FontWeight fontWeight = ui.FontWeight.normal,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.left,
        fontSize: fontSize,
        maxLines: 1,
      ),
    );
    builder.pushStyle(
      ui.TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        shadows: const [
          ui.Shadow(
            blurRadius: 4,
            color: ui.Color(0xAA000000),
            offset: ui.Offset(1, 1),
          ),
        ],
      ),
    );
    builder.addText(text);
    builder.pop();

    final paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    return paragraph;
  }
}
