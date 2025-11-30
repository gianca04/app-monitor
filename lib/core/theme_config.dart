import 'package:flutter/material.dart';

class AppTheme {
  // --- 1. PALETA DE COLORES INDUSTRIAL ---
  static const Color background = Color(0xFF121619); // Fondo ultra oscuro
  static const Color surface = Color(0xFF1E2329); // Superficies de tarjetas

  static const Color primaryAccent = Color(
    0xFFFFAB00,
  ); // Industrial Amber (Acción principal)
  static const Color secondaryAccent = Color(
    0xFF03DAC6,
  ); // Electric Teal (Indicadores de estado)

  static const Color textPrimary = Color(
    0xFFE1E4E8,
  ); // Blanco hueso (Legibilidad alta)
  static const Color textSecondary = Color(
    0xFF8B949E,
  ); // Gris metálico (Metadatos)

  static const Color border = Color(0xFF30363D); // Bordes sutiles
  static const Color borderHighContrast = Color(
    0xFF6E7681,
  ); // Bordes activos/focus

  static const Color error = Color(0xFFF85149); // Rojo alerta industrial
  static const Color success = Color(0xFF3FB950); // Verde terminal
  static const Color warning = Color(0xFFD29922); // Amarillo precaución
  static const Color info = Color(0xFF58A6FF); // Azul informativo

  // Adicionales
  static const Color inputFill = Color(
    0xFF0D1117,
  ); // Input más oscuro que la tarjeta para profundidad "hundida"

  // --- 2. CONSTANTES DE DISEÑO ---
  static const double kRadius = 4.0; // La Regla del 4
  static const double kBorderWidth = 1.0;

  // --- 3. TEMA UNIFICADO ---
  static ThemeData get industrialTheme {
    // Definimos el ColorScheme base para que Flutter sepa qué colores usar en sus widgets internos
    final colorScheme =
        ColorScheme.dark(
          primary: primaryAccent,
          secondary: secondaryAccent,
          surface: surface,
          surfaceContainerHighest: Color(
            0xFF262C36,
          ), // Para badges y fondos secundarios
          onPrimary: Colors.black, // Texto negro sobre el ámbar para contraste
          onSurface: textPrimary,
          onSurfaceVariant: textSecondary,
          error: error,
          outline: border, // CRUCIAL: Define el color de bordes por defecto
          outlineVariant: border.withOpacity(0.5),
        ).copyWith(
          surface: surface,
        ); // Corrección para asegurar background correcto

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      primaryColor: primaryAccent,

      // Fuente por defecto (Opcional: Si usas GoogleFonts, ponlo aquí)
      fontFamily:
          'Roboto', // O 'Inter', 'JetBrains Mono' queda genial para industrial
      // --- APP BAR ---
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0, // Evita cambio de color al scrollear
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0, // Tracking industrial
        ),
        iconTheme: IconThemeData(color: textPrimary),
        shape: Border(
          bottom: BorderSide(color: border, width: 1),
        ), // Línea divisoria integrada
      ),

      // --- TARJETAS (Industrial Cards) ---
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0, // Regla: Cero sombras
        margin: EdgeInsets.zero, // Control manual de márgenes en listas
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: const BorderSide(color: border, width: kBorderWidth),
        ),
      ),

      // --- INPUTS ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        // Borde Normal
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadius)),
          borderSide: BorderSide(color: border),
        ),
        // Borde Foco (Activo)
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadius)),
          borderSide: BorderSide(color: primaryAccent, width: 1.5),
        ),
        // Borde Error
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadius)),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadius)),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: TextStyle(
          color: textSecondary.withOpacity(0.5),
          fontSize: 14,
        ),
      ),

      // --- BOTONES (Unificación de formas) ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryAccent,
          side: const BorderSide(color: borderHighContrast),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary, // Por defecto blanco/gris
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius),
          ),
        ),
      ),

      // --- FAB (Botón Flotante) ---
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryAccent,
        foregroundColor: Colors.black,
        elevation:
            2, // Leve elevación permitida en FAB para separarlo del contenido
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(kRadius),
          ), // Cuadrado redondeado
        ),
      ),

      // --- DIVIDERS ---
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // --- TABS (Pestañas) ---
      tabBarTheme: const TabBarThemeData(
        indicatorColor: primaryAccent,
        labelColor: primaryAccent,
        unselectedLabelColor: textSecondary,
        dividerColor:
            Colors.transparent, // Ocultamos el divider default del TabBar
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // --- DIÁLOGOS ---
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: const BorderSide(color: borderHighContrast, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      // --- TEXTOS (Tipografía Técnica) ---
      textTheme: TextTheme(
        // Títulos Grandes
        titleLarge: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: -0.5,
        ),
        // Títulos Medios (Nombres de reportes)
        titleMedium: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.1,
        ),
        // Cuerpo normal
        bodyMedium: const TextStyle(
          color: textPrimary, // Mejor lectura que el gris oscuro
          fontSize: 14,
        ),
        // Metadatos y etiquetas (Labels)
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
