import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:monitor/core/theme_config.dart';

class SignatureBox extends StatelessWidget {
  final String title;
  final Uint8List? bytes;
  final VoidCallback onTap;

  const SignatureBox({
    super.key,
    required this.title,
    required this.bytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSignature = bytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Etiqueta superior (Industrial Label)
        Text(
          title.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),

        // 2. Contenedor de la Firma
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.kRadius),
            child: Container(
              height: 100, // Altura fija para consistencia en el Row
              width: double.infinity,
              decoration: BoxDecoration(
                // Si hay firma, fondo blanco para contraste. Si no, fondo de input oscuro.
                color: hasSignature ? Colors.white : AppTheme.inputFill,
                borderRadius: BorderRadius.circular(AppTheme.kRadius),
                border: Border.all(
                  // Si hay firma, borde verde (éxito) o primario. Si no, borde normal.
                  color: hasSignature 
                      ? AppTheme.success.withOpacity(0.5) 
                      : AppTheme.border,
                  width: 1,
                ),
              ),
              child: hasSignature
                  ? _buildSignedContent(bytes!)
                  : _buildEmptyState(theme),
            ),
          ),
        ),
      ],
    );
  }

  // Estado: FIRMADO
  Widget _buildSignedContent(Uint8List data) {
    return Stack(
      children: [
        // La imagen de la firma
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Image.memory(
              data,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
        // Badge de "Editar" en la esquina
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(AppTheme.kRadius),
            ),
            child: const Icon(
              Icons.edit,
              size: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // Estado: VACÍO (Placeholder)
  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.draw_outlined, // Icono de "Firma manual"
          color: AppTheme.textSecondary.withOpacity(0.5),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          'TOCAR PARA FIRMAR',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}