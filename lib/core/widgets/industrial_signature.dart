import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme_config.dart';

/// Widget reutilizable para mostrar y capturar firmas con estilo industrial.
/// 
/// Ejemplo de uso:
/// ```dart
/// IndustrialSignatureBox(
///   title: 'FIRMA DEL SUPERVISOR',
///   base64: _supervisorSignature,
///   onTap: () => _pickSignature(true),
/// )
/// ```
class IndustrialSignatureBox extends StatelessWidget {
  /// Título que se muestra encima del área de firma
  final String title;

  /// Firma en formato base64 (puede incluir prefijo data:image/png;base64,)
  final String? base64;

  /// Callback cuando se toca el área de firma
  final VoidCallback onTap;

  /// Altura del área de firma
  final double height;

  /// Si se debe mostrar un borde con acento cuando hay firma
  final bool showAccentBorder;

  const IndustrialSignatureBox({
    super.key,
    required this.title,
    this.base64,
    required this.onTap,
    this.height = 80,
    this.showAccentBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasSignature = base64 != null && base64!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Área de firma
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.kRadius),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border.all(
                color: showAccentBorder && hasSignature
                    ? AppTheme.primaryAccent
                    : AppTheme.border,
                width: showAccentBorder && hasSignature ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(AppTheme.kRadius),
            ),
            child: hasSignature
                ? _buildSignatureImage(base64!)
                : _buildPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.draw_outlined,
            color: Colors.grey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            'TOCAR PARA FIRMAR',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureImage(String base64String) {
    try {
      // Manejar formato data URL: "data:image/png;base64,..."
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }

      final Uint8List bytes = base64Decode(cleanBase64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.kRadius - 1),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.redAccent,
                  size: 24,
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      return const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.redAccent,
          size: 24,
        ),
      );
    }
  }
}

/// Row de dos firmas lado a lado con estilo industrial.
/// 
/// Ejemplo de uso:
/// ```dart
/// IndustrialSignatureRow(
///   supervisorTitle: 'SUPERVISOR',
///   supervisorBase64: _supervisorSignature,
///   onSupervisorTap: () => _pickSignature(true),
///   managerTitle: 'GERENCIA / CLIENTE',
///   managerBase64: _managerSignature,
///   onManagerTap: () => _pickSignature(false),
/// )
/// ```
class IndustrialSignatureRow extends StatelessWidget {
  final String supervisorTitle;
  final String? supervisorBase64;
  final VoidCallback onSupervisorTap;
  
  final String managerTitle;
  final String? managerBase64;
  final VoidCallback onManagerTap;

  final double height;

  const IndustrialSignatureRow({
    super.key,
    this.supervisorTitle = 'SUPERVISOR',
    this.supervisorBase64,
    required this.onSupervisorTap,
    this.managerTitle = 'GERENCIA / CLIENTE',
    this.managerBase64,
    required this.onManagerTap,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: IndustrialSignatureBox(
            title: supervisorTitle,
            base64: supervisorBase64,
            onTap: onSupervisorTap,
            height: height,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: IndustrialSignatureBox(
            title: managerTitle,
            base64: managerBase64,
            onTap: onManagerTap,
            height: height,
          ),
        ),
      ],
    );
  }
}

/// Dialog/Sheet para capturar firmas con estilo industrial.
/// 
/// Uso:
/// ```dart
/// final signature = await IndustrialSignatureSheet.show(
///   context,
///   title: 'FIRMA DEL SUPERVISOR',
/// );
/// ```
class IndustrialSignatureSheet {
  /// Muestra el sheet de firma y retorna el base64 de la firma o null si se cancela.
  static Future<String?> show(
    BuildContext context, {
    required String title,
  }) async {
    return await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _SignatureSheetContent(title: title),
      ),
    );
  }
}

class _SignatureSheetContent extends StatefulWidget {
  final String title;

  const _SignatureSheetContent({required this.title});

  @override
  State<_SignatureSheetContent> createState() => _SignatureSheetContentState();
}

class _SignatureSheetContentState extends State<_SignatureSheetContent> {
  final List<Offset?> _points = [];

  // Dimensiones visuales
  static const double _canvasWidth = 305.0;
  static const double _canvasHeight = 144.0;

  // Factor de calidad HD
  static const double _exportScale = 3.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              widget.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),

            // Instrucción
            const Text(
              'Firme dentro del recuadro',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Canvas de firma
            Center(
              child: Container(
                height: _canvasHeight,
                width: _canvasWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _points.add(details.localPosition);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        final localPos = details.localPosition;
                        if (localPos.dx >= 0 &&
                            localPos.dx <= _canvasWidth &&
                            localPos.dy >= 0 &&
                            localPos.dy <= _canvasHeight) {
                          _points.add(localPos);
                        }
                      });
                    },
                    onPanEnd: (details) {
                      _points.add(null);
                    },
                    child: CustomPaint(
                      painter: _SignaturePainter(_points),
                      size: const Size(_canvasWidth, _canvasHeight),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _points.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.kRadius),
                      ),
                    ),
                    child: const Text(
                      'LIMPIAR',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _points.isEmpty ? null : _saveSignature,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.kRadius),
                      ),
                      disabledBackgroundColor: AppTheme.border,
                    ),
                    child: const Text(
                      'GUARDAR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSignature() async {
    if (_points.isEmpty) return;

    final navigator = Navigator.of(context);
    final recorder = ui.PictureRecorder();

    // Canvas virtual escalado
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(
        Offset.zero,
        const Offset(_canvasWidth * _exportScale, _canvasHeight * _exportScale),
      ),
    );

    canvas.scale(_exportScale);

    // Fondo blanco
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _canvasWidth, _canvasHeight),
      bgPaint,
    );

    // Pincel
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Dibujar puntos
    for (int i = 0; i < _points.length - 1; i++) {
      if (_points[i] != null && _points[i + 1] != null) {
        canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (_canvasWidth * _exportScale).toInt(),
      (_canvasHeight * _exportScale).toInt(),
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final base64String = 'data:image/png;base64,${base64Encode(bytes)}';

    navigator.pop(base64String);
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
