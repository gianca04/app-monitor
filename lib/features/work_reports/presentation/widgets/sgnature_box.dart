import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:monitor/core/theme_config.dart';

class SignatureBox extends StatelessWidget {
  final String title;
  final String? base64;
  final VoidCallback onTap;

  const SignatureBox({
    super.key,
    required this.title,
    required this.base64,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSignature = base64 != null;

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
                  ? _buildSignedContent(base64!)
                  : _buildEmptyState(theme),
            ),
          ),
        ),
      ],
    );
  }

  // Estado: FIRMADO
  Widget _buildSignedContent(String data) {
    return Stack(
      children: [
        // La imagen de la firma
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: _buildSignatureImage(data),
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

  // Método para manejar tanto URLs como base64
  Widget _buildSignatureImage(String data) {
    print('🖼️ [SIGNATURE_BOX] Building signature image for data: ${data.substring(0, min(50, data.length))}...');

    // Si es una URL (empieza con http/https)
    if (data.startsWith('http://') || data.startsWith('https://')) {
      print('🖼️ [SIGNATURE_BOX] Loading as network image: $data');
      return Image.network(
        data,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('🖼️ [SIGNATURE_BOX] Network image loaded successfully');
            return child;
          }
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ [SIGNATURE_BOX] Error loading network image: $error');
          print('❌ [SIGNATURE_BOX] Stack trace: $stackTrace');
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.red, size: 32),
          );
        },
      );
    }
    // Si es base64 (contiene el prefijo data:image)
    else if (data.contains('data:image/png;base64,')) {
      print('🖼️ [SIGNATURE_BOX] Loading as base64 image');
      try {
        final bytes = base64Decode(data.split(',').last);
        print('🖼️ [SIGNATURE_BOX] Base64 decoded successfully, ${bytes.length} bytes');
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: double.infinity,
        );
      } catch (e) {
        print('❌ [SIGNATURE_BOX] Error decoding base64: $e');
        // Si falla el decode, mostrar error
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.red, size: 32),
        );
      }
    }
    // Caso por defecto (URL relativa o formato desconocido)
    else {
      print('🖼️ [SIGNATURE_BOX] Loading as fallback network image: $data');
      return Image.network(
        data,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('🖼️ [SIGNATURE_BOX] Fallback network image loaded successfully');
            return child;
          }
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ [SIGNATURE_BOX] Error loading fallback network image: $error');
          print('❌ [SIGNATURE_BOX] Stack trace: $stackTrace');
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.red, size: 32),
          );
        },
      );
    }
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