import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF5F1E8);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightPrimaryText = Color(0xFF333333);
  static const Color lightSecondaryText = Color(0xFF666666);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkCardBackground = Color(0xFF2D2D2D);
  static const Color darkPrimaryText = Color(0xFFE0E0E0);
  static const Color darkSecondaryText = Color(0xFFB0B0B0);

  // Brand Colors
  static const Color primaryGreen = Color(0xFF2D5016);
  static const Color primaryGreenLight = Color(0xFF66BB6A);
  static const Color secondaryBlue = Color(0xFF1E3A5F);
  static const Color secondaryBlueLigh = Color(0xFF64B5F6);
  static const Color warningOrange = Color(0xFFFF8C42);
  static const Color criticalRed = Color(0xFFd32f2f);
  static const Color criticalRedLight = Color(0xFFFF5252);
  static const Color successGreen = Color(0xFF2D5016);
  static const Color successGreenLight = Color(0xFF81C784);
  static const Color borderGray = Color(0xFF999999);
  static const Color borderGrayDark = Color(0xFF555555);

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: primaryGreen,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: secondaryBlue,
      tertiary: warningOrange,
      error: criticalRed,
      surface: lightCardBackground,
      background: lightBackground,
      onBackground: lightPrimaryText,
      onSurface: lightPrimaryText,
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: lightCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // Text Theme
    textTheme: GoogleFonts.robotoTextTheme().copyWith(
      headlineSmall: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: lightPrimaryText,
      ),
      titleMedium: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: lightPrimaryText,
      ),
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        color: lightPrimaryText,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        color: lightSecondaryText,
      ),
      labelLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: criticalRed),
      ),
      labelStyle: GoogleFonts.roboto(
        fontSize: 14,
        color: lightSecondaryText,
      ),
      hintStyle: GoogleFonts.roboto(
        fontSize: 14,
        color: lightSecondaryText,
      ),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreen;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreen.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primaryGreenLight,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: primaryGreenLight,
      secondary: secondaryBlueLigh,
      tertiary: warningOrange,
      error: criticalRedLight,
      surface: darkCardBackground,
      background: darkBackground,
      onBackground: darkPrimaryText,
      onSurface: darkPrimaryText,
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: darkCardBackground,
      foregroundColor: darkPrimaryText,
      elevation: 0,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: darkPrimaryText,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: darkCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreenLight,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // Text Theme
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineSmall: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: darkPrimaryText,
      ),
      titleMedium: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: darkPrimaryText,
      ),
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        color: darkPrimaryText,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        color: darkSecondaryText,
      ),
      labelLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderGrayDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderGrayDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryGreenLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: criticalRedLight),
      ),
      labelStyle: GoogleFonts.roboto(
        fontSize: 14,
        color: darkSecondaryText,
      ),
      hintStyle: GoogleFonts.roboto(
        fontSize: 14,
        color: darkSecondaryText,
      ),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreenLight;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGreenLight.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),
  );
}
