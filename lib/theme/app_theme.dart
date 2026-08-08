import 'package:flutter/material.dart';

class AppTheme {

  // =========================================
  // COLORS (Premium iOS Dark Theme)
  // =========================================

  static const Color background =
  Color(0xFF000000); // iOS System Background (True OLED Black)

  static const Color card =
  Color(0xFF1C1C1E); // iOS System Gray 6

  static const Color cardLight =
  Color(0xFF2C2C2E); // iOS System Gray 5

  static const Color primary =
  Color(0xFF0A84FF); // iOS System Blue

  static const Color accent =
  Color(0xFF30D158); // iOS System Green (Eco-clean)

  static const Color success =
  Color(0xFF30D158);

  static const Color danger =
  Color(0xFFFF453A); // iOS System Red

  static const Color warning =
  Color(0xFFFF9F0A); // iOS System Orange

  static const Color textPrimary =
      Colors.white;

  static const Color textSecondary =
  Color(0xFF8E8E93); // iOS System Gray

  // =========================================
  // GRADIENTS (iOS Style / 100% Code-based)
  // =========================================

  static const Gradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF0A84FF), // iOS System Blue
      Color(0xFF5E5CE6), // iOS System Indigo
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
        BorderRadius.circular(14), // Apple standard rounded corners

        side: const BorderSide(
          color: Color(0xFF2C2C2E), // Subtly define card boundaries
          width: 0.5,
        ),
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

        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(

        borderRadius:
        BorderRadius.circular(12), // Apple standard input rounding

        borderSide: const BorderSide(
          color: Color(0xFF2C2C2E),
          width: 0.5,
        ),
      ),

      enabledBorder:
      OutlineInputBorder(

        borderRadius:
        BorderRadius.circular(12),

        borderSide:
        const BorderSide(
          color: Color(0xFF2C2C2E),
          width: 0.5,
        ),
      ),

      focusedBorder:
      OutlineInputBorder(

        borderRadius:
        BorderRadius.circular(12),

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
          vertical: 16,
        ),

        shape: RoundedRectangleBorder(

          borderRadius:
          BorderRadius.circular(12),
        ),

        textStyle: const TextStyle(

          fontSize: 16,

          fontWeight:
          FontWeight.w600,
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