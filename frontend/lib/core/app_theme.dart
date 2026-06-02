import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color secondaryColor = Color(0xFFFF6584);
  static const Color accentColor = Color(0xFF43C6AC);

  // Light Mode
  static const Color lightBg = Color(0xFFF8F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightTextSub = Color(0xFF6B7280);

  // Dark Mode
  static const Color darkBg = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkText = Color(0xFFF1F1F5);
  static const Color darkTextSub = Color(0xFF9CA3AF);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: primaryColor,
        scaffoldBackgroundColor: lightBg,
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          headlineLarge: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: lightText,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: lightText,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: lightText,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: lightText,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            color: lightTextSub,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: lightSurface,
          elevation: 0,
          scrolledUnderElevation: 2,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
          iconTheme: const IconThemeData(color: lightText),
        ),
        cardTheme: CardThemeData(
          color: lightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: primaryColor,
        scaffoldBackgroundColor: darkBg,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
          headlineLarge: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: darkText,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            color: darkTextSub,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkSurface,
          elevation: 0,
          scrolledUnderElevation: 2,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
          iconTheme: const IconThemeData(color: darkText),
        ),
        cardTheme: CardThemeData(
          color: darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}
