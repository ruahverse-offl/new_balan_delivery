import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Same palette as the React Native `new_balan_delivery` constants/theme.ts
class AppColors {
  static const Color primary = Color(0xFF0056B3);
  static const Color primaryDark = Color(0xFF004085);
  static const Color primaryLight = Color(0xFFE7F3FF);
  static const Color secondary = Color(0xFF28A745);
  static const Color secondaryDark = Color(0xFF1E7E34);
  static const Color secondaryLight = Color(0xFFE8F5E9);
  static const Color accent = Color(0xFF5BC0DE);
  static const Color accentBlue = Color(0xFF1D4ED8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  static const List<Color> gradientHero = [Color(0xFF0F172A), Color(0xFF1D4ED8)];
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: false,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.gray50,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.gray900),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.gray900,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.gray100, width: 1),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray400,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(12),
        fillColor: AppColors.white,
        filled: true,
        hintStyle: const TextStyle(color: AppColors.gray500),
      ),
      dividerColor: AppColors.gray200,
    );
  }
}
