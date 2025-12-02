import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../../core/widgets/modern_bottom_modal.dart';

class IndustrialSignatureSheet {
  static Future<String?> show(BuildContext context, {required String title}) async {
    return await ModernBottomModal.show<String?>(
      context,
      title: title,
      content: const _SignatureCanvas(),
      actions: const [], 
    );
  }
}

class _SignatureCanvas extends StatefulWidget {
  const _SignatureCanvas();

  @override
  State<_SignatureCanvas> createState() => _SignatureCanvasState();
}

class _SignatureCanvasState extends State<_SignatureCanvas> {
  final List<Offset?> _points = [];
  
  // Dimensiones VISUALES (lo que ve el usuario en el celular)
  static const double _canvasWidth = 305.0;
  static const double _canvasHeight = 144.0;

  // Factor de Calidad HD: 3.0 significa que la imagen será 3 veces más grande y nítida
  static const double _exportScale = 3.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Firme dentro del recuadro",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 8),

        // Signature Area
        Center(
          child: Container(
            height: _canvasHeight,
            width: _canvasWidth,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              // Borde sutil para delimitar el área
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                // MEJORA: Usamos localPosition para evitar el desfase del cursor
                onPanUpdate: (details) {
                  setState(() {
                    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                       Offset localPos = details.localPosition;
                       // Validamos límites
                       if (localPos.dx >= 0 && 
                           localPos.dx <= _canvasWidth && 
                           localPos.dy >= 0 && 
                           localPos.dy <= _canvasHeight) {
                         _points.add(localPos);
                       }
                    }
                  });
                },
                onPanStart: (details) {
                  setState(() {
                    _points.add(details.localPosition);
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

        // Buttons
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
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'LIMPIAR',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _points.isEmpty ? null : _saveSignature,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text(
                  'GUARDAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveSignature() async {
    if (_points.isEmpty) return;

    final navigator = Navigator.of(context);
    final recorder = ui.PictureRecorder();

    // 1. TRUCO HD: Creamos un canvas virtual 3 VECES más grande
    final canvas = Canvas(recorder, Rect.fromPoints(
      Offset.zero, 
      const Offset(_canvasWidth * _exportScale, _canvasHeight * _exportScale)
    ));

    // 2. Escalamos el canvas. Todo lo que dibujes ahora se multiplicará por 3 automáticamente
    canvas.scale(_exportScale);

    // 3. Pintamos el fondo blanco (usando dimensiones base, el scale se encarga del resto)
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _canvasWidth, _canvasHeight), 
      bgPaint
    );

    // 4. Configuración del pincel
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5 // Grosor base. Al escalar x3 se verá sólido y profesional.
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 5. Dibujamos los puntos
    for (int i = 0; i < _points.length - 1; i++) {
      if (_points[i] != null && _points[i + 1] != null) {
        canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
      }
    }

    // 6. Finalizamos grabación
    final picture = recorder.endRecording();
    
    // 7. GENERAMOS LA IMAGEN EN HD (915 x 432 px)
    final image = await picture.toImage(
      (_canvasWidth * _exportScale).toInt(), 
      (_canvasHeight * _exportScale).toInt()
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    // Listo para Laravel
    final base64String = 'data:image/png;base64,${base64Encode(bytes)}';

    navigator.pop(base64String);
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    // Pincel para la vista previa en el celular (sin escalar)
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