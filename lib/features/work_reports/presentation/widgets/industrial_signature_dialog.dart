import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:monitor/core/theme_config.dart';
// Importa tu archivo donde está ModernBottomModal
import 'package:monitor/core/widgets/modern_bottom_modal.dart'; 

class IndustrialSignatureSheet extends StatefulWidget {
  final String title;

  const IndustrialSignatureSheet({super.key, required this.title});

  // Método estático helper para facilitar la llamada
  static Future<Uint8List?> show(BuildContext context, {required String title}) {
    return showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true, // Vital para que crezca
      backgroundColor: Colors.transparent, // El modal maneja el fondo
      elevation: 0,
      enableDrag: false, // Mejor false para firmas para evitar cerrar al dibujar
      isDismissible: false,
      builder: (context) => IndustrialSignatureSheet(title: title),
    );
  }

  @override
  State<IndustrialSignatureSheet> createState() => _IndustrialSignatureSheetState();
}

class _IndustrialSignatureSheetState extends State<IndustrialSignatureSheet> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  final Color _penColor = const Color(0xFF001F3F);

  @override
  Widget build(BuildContext context) {
    // AQUI USAMOS EL MODAL CORRECTAMENTE COMO WIDGET DE LAYOUT
    return ModernBottomModal(
      title: widget.title,
      // 1. CONTENT: Solo el área de firma
      content: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderHighContrast),
          borderRadius: BorderRadius.circular(AppTheme.kRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.kRadius),
          child: Stack(
            children: [
              // Guías visuales
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Divider(color: Colors.grey.withOpacity(0.5)),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Text(
                  "Firme dentro del recuadro",
                  style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 10),
                ),
              ),
              // El Pad
              SfSignaturePad(
                key: _signaturePadKey,
                minimumStrokeWidth: 2.0,
                maximumStrokeWidth: 4.0,
                strokeColor: _penColor,
                backgroundColor: Colors.transparent,
              ),
            ],
          ),
        ),
      ),
      // 2. ACTIONS: Los botones que controlan el estado
      actions: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _signaturePadKey.currentState?.clear(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('LIMPIAR'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('GUARDAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    // Lógica de conversión
    final data = await _signaturePadKey.currentState!.toImage(pixelRatio: 3.0);
    final byteData = await data.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null && mounted) {
      final bytes = byteData.buffer.asUint8List();
      Navigator.of(context).pop(bytes); // Retornamos los bytes al cerrar
    }
  }
}