import 'package:flutter/material.dart';

class AppTheme {

  // =========================================
  // COLORS
  // =========================================

  static const Color background =
  Color(0xFF0F172A);

  static const Color card =
  Color(0xFF1E293B);

  static const Color cardLight =
  Color(0xFF334155);

  static const Color primary =
  Color(0xFF3B82F6);

  static const Color accent =
  Color(0xFF06B6D4);

  static const Color success =
  Color(0xFF22C55E);

  static const Color danger =
  Color(0xFFEF4444);

  static const Color warning =
  Color(0xFFF59E0B);

  static const Color textPrimary =
      Colors.white;

  static const Color textSecondary =
  Color(0xFFCBD5E1);

  // =========================================
  // DARK THEME
  // =========================================

  static ThemeData darkTheme = ThemeData(

    brightness: Brightness.dark,

    useMaterial3: true,

    scaffoldBackgroundColor:
    background,

    primaryColor: primary,

    fontFamily: "Roboto",

    colorScheme: const ColorScheme.dark(

      primary: primary,

      secondary: accent,

      surface: card,
    ),

    // =========================================
    // APP BAR
    // =========================================

    appBarTheme: const AppBarTheme(

      backgroundColor: background,

      elevation: 0,

      centerTitle: true,

      titleTextStyle: TextStyle(

        color: textPrimary,

        fontSize: 20,

        fontWeight: FontWeight.bold,
      ),

      iconTheme: IconThemeData(
        color: textPrimary,
      ),
    ),

    // =========================================
    // CARD
    // =========================================

    cardTheme: CardThemeData(

      color: card,

      elevation: 0,

      shape: RoundedRectangleBorder(

        borderRadius:
        BorderRadius.circular(20),
      ),

      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
    ),

    // =========================================
    // INPUT
    // =========================================

    inputDecorationTheme:
    InputDecorationTheme(

      filled: true,

      fillColor: card,

      contentPadding:
      const EdgeInsets.symmetric(

        horizontal: 18,
        vertical: 18,
      ),

      border: OutlineInputBorder(

        borderRadius:
        BorderRadius.circular(18),

        borderSide: BorderSide.none,
      ),

      enabledBorder:
      OutlineInputBorder(

        borderRadius:
        BorderRadius.circular(18),

        borderSide:
        BorderSide.none,
      ),

      focusedBorder:
      OutlineInputBorder(

        borderRadius:
        BorderRadius.circular(18),

        borderSide:
        const BorderSide(
          color: primary,
          width: 1.5,
        ),
      ),

      hintStyle: const TextStyle(
        color: textSecondary,
      ),
    ),

    // =========================================
    // BUTTON
    // =========================================

    elevatedButtonTheme:
    ElevatedButtonThemeData(

      style: ElevatedButton.styleFrom(

        backgroundColor: primary,

        foregroundColor: Colors.white,

        elevation: 0,

        padding:
        const EdgeInsets.symmetric(
          vertical: 18,
        ),

        shape: RoundedRectangleBorder(

          borderRadius:
          BorderRadius.circular(18),
        ),

        textStyle: const TextStyle(

          fontSize: 16,

          fontWeight:
          FontWeight.bold,
        ),
      ),
    ),

    // =========================================
    // TEXT
    // =========================================

    textTheme: const TextTheme(

      headlineLarge: TextStyle(

        color: textPrimary,

        fontWeight: FontWeight.bold,
      ),

      bodyLarge: TextStyle(
        color: textPrimary,
      ),

      bodyMedium: TextStyle(
        color: textSecondary,
      ),
    ),

    // =========================================
    // ICONS
    // =========================================

    iconTheme: const IconThemeData(
      color: textPrimary,
    ),
  );
}