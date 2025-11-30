// core/theme/app_design_system.dart

import 'package:flutter/material.dart';

class AppDimens {
  static const double radius = 4.0;
  static const double iconSizeSmall = 16.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
}

class AppStyles {
  // Estilo para las etiquetas (HEADERS)
  static TextStyle labelStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      fontSize: 10,
      letterSpacing: 1.0,
      fontWeight: FontWeight.bold,
      // Opcional: Si quieres que siempre sean del color primario
      // color: Theme.of(context).colorScheme.primary, 
    );
  }

  // Estilo para los valores (DATA)
  static TextStyle valueStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
  }

  // Decoración para contenedores "Industrial"
  static BoxDecoration industrialDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
      ),
      borderRadius: BorderRadius.circular(AppDimens.radius),
    );
  }
}