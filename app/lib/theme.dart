import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ilova ranglari — islomiy/nafis: zumrad yashil + oltin.
class AppColors {
  static const emerald = Color(0xFF0E7C66);
  static const emeraldDark = Color(0xFF0A5C4B);
  static const gold = Color(0xFFD4A537);
  static const cream = Color(0xFFF7F3E9);
  static const ink = Color(0xFF1C2B27);
  static const softGreen = Color(0xFFE3F0EB);
  static const coral = Color(0xFFE0603A);
  static const success = Color(0xFF2E9E5B);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.emerald,
        primary: AppColors.emerald,
        secondary: AppColors.gold,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: true,
      ),
    );
  }

  /// Arabcha matn uchun shrift (Amiri — nasx uslubi, harakatlarni yaxshi ko'rsatadi).
  static TextStyle arabic({double size = 40, Color color = AppColors.ink, FontWeight w = FontWeight.w600}) {
    return GoogleFonts.amiri(fontSize: size, color: color, fontWeight: w, height: 1.4);
  }
}
