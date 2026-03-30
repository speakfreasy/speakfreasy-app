import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SpeakFreasy Design System
/// 1920s speakeasy/art deco aesthetic

class SFColors {
  // Gold palette
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF4E4BA);
  static const Color goldDark = Color(0xFFB8960C);
  
  // Backgrounds
  static const Color black = Color(0xFF0D0D0D);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF242424);
  
  // Text
  static const Color cream = Color(0xFFF5F0E1);
  static const Color creamMuted = Color(0xFFC9C4B5);
  
  // Borders
  static const Color border = Color(0xFF3D3D3D);
  
  // Status
  static const Color success = Color(0xFF4A7C59);
  static const Color error = Color(0xFF8B3A3A);
  
  // Gold gradient for primary actions
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class SFTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SFColors.black,
      colorScheme: const ColorScheme.dark(
        primary: SFColors.gold,
        secondary: SFColors.goldLight,
        surface: SFColors.surface,
        background: SFColors.black,
        error: SFColors.error,
        onPrimary: SFColors.black,
        onSecondary: SFColors.black,
        onSurface: SFColors.cream,
        onBackground: SFColors.cream,
        onError: SFColors.cream,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          color: SFColors.cream,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          color: SFColors.cream,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          color: SFColors.cream,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          color: SFColors.cream,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          color: SFColors.cream,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          color: SFColors.cream,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.inter(
          color: SFColors.cream,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          color: SFColors.cream,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.inter(
          color: SFColors.cream,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: SFColors.cream,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: SFColors.cream,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.inter(
          color: SFColors.creamMuted,
          fontSize: 12,
        ),
        labelLarge: GoogleFonts.inter(
          color: SFColors.cream,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: GoogleFonts.inter(
          color: SFColors.creamMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.inter(
          color: SFColors.creamMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SFColors.charcoal,
        elevation: 0,
        iconTheme: const IconThemeData(color: SFColors.gold),
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: SFColors.gold,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: SFColors.charcoal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SFColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SFColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SFColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SFColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SFColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SFColors.error),
        ),
        labelStyle: GoogleFonts.inter(color: SFColors.creamMuted),
        hintStyle: GoogleFonts.inter(color: SFColors.creamMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: SFColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
