import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Opcional, si usas fuentes externas

class AppTheme {
  // --- Definición de Colores ---
  static const Color background = Color(0xFF121619);
  static const Color surface = Color(0xFF1E2329);
  static const Color primaryAccent = Color(0xFFFFAB00); // Industrial Amber
  static const Color secondaryAccent = Color(0xFF03DAC6); // Electric Teal (opcional)
  static const Color textPrimary = Color(0xFFE1E4E8);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color border = Color(0xFF30363D);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Colores adicionales para consistencia
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color inputFill = Color(0xFF2A2A2A);
  static const Color divider = Color(0xFF30363D);

  static ThemeData get industrialTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryAccent,
      
      // Estilo del AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2, // Espaciado técnico
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // Estilo de Tarjetas
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Bordes casi rectos
          side: const BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Botón Flotante (FAB)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryAccent,
        foregroundColor: Colors.black, // Contraste alto sobre ámbar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)), // Cuadrado redondeado
        ),
      ),

      // Textos
      textTheme: TextTheme(
        titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        bodyMedium: const TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textSecondary.withOpacity(0.7)),
      ),

      // Íconos
      iconTheme: const IconThemeData(color: textSecondary),

      // Diálogos
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: border),
        ),
      ),

      // Inputs unificados
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: const BorderSide(color: primaryAccent, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),

      colorScheme: ColorScheme.dark(
        primary: primaryAccent,
        surface: surface,
        error: error,
        onPrimary: Colors.black,
        onSurface: textPrimary,
      ).copyWith(background: background),
    );
  }
}