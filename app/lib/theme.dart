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

  // Har modulning o'z urg'u rangi — hammasi bir xil yashil bo'lsa ekran
  // «bir tekis» va zerikarli tuyuladi; farqli ranglar ko'zga yo'l ko'rsatadi.
  static const teal = Color(0xFF1B8A9E);
  static const indigo = Color(0xFF5B5BD6);
  static const amber = Color(0xFFE39B1E);

  /// Hero va chuqur fonlar uchun eng to'q yashil.
  static const deep = Color(0xFF07332B);

  /// Oltinning yorug' tusi — yaltiroq chiziqlar va urg'ular uchun.
  static const goldLight = Color(0xFFF2D27A);
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
      // Barcha sahifa o'tishlari uchun zamonaviy, silliq zoom-fade (Material 3).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Arabcha matn uchun shrift (Amiri — nasx uslubi, harakatlarni yaxshi ko'rsatadi).
  ///
  /// Shrift ilova ichida (assets/fonts). Internetdan yuklanmaydi: aks holda
  /// u kelgunicha matn zaxira shriftda chiziladi va harakatlar harfga
  /// ulanmay, so'z ustida ajralib turadi.
  ///
  /// Amiri'da faqat 400 va 700 og'irlik bor. Oradagi qiymat so'ralsa Flutter
  /// eng yaqinini oladi, «sun'iy qalinlashtirish» qilmaydi — shuning uchun
  /// harakatlar joyida qoladi.
  static TextStyle arabic({
    double size = 40,
    Color color = AppColors.ink,
    FontWeight w = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: 'Amiri',
      fontSize: size,
      color: color,
      fontWeight: w,
      height: 1.4,
    );
  }
}
