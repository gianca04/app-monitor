import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class DioErrorHandler {
  static String getErrorMessage(Object error, {required String defaultMessage}) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Error de conexión. Verifica tu conexión a internet e intenta nuevamente.';
      } else if (error.type == DioExceptionType.badResponse) {
        final data = error.response?.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'].toString();
        }
        return 'Error del servidor. Inténtalo más tarde.';
      } else if (error.type == DioExceptionType.cancel) {
        return 'La solicitud fue cancelada.';
      }
    }
    return defaultMessage;
  }

  static IconData getIconForError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('conexión') || lower.contains('timeout') || lower.contains('internet')) {
      return Icons.wifi_off_rounded;
    } else if (lower.contains('servidor') || lower.contains('server') || lower.contains('bad response')) {
      return Icons.dns_rounded;
    } else if (lower.contains('cancel') || lower.contains('cancelada')) {
      return Icons.cancel_outlined;
    } else if (lower.contains('no se encontr') || lower.contains('no encontrado') || lower.contains('not found')) {
      return Icons.search_off_rounded;
    }
    return Icons.error_outline_rounded;
  }

  static String getTitleForError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('conexión') || lower.contains('timeout') || lower.contains('internet')) {
      return 'ERROR DE CONEXIÓN';
    } else if (lower.contains('servidor') || lower.contains('server') || lower.contains('bad response')) {
      return 'ERROR DEL SERVIDOR';
    } else if (lower.contains('cancel') || lower.contains('cancelada')) {
      return 'SOLICITUD CANCELADA';
    }
    return 'ERROR DEL SISTEMA';
  }
}
