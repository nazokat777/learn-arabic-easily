import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ilova ranglari — islomiy/nafis: zumrad yashil + oltin.
///
/// Ikki qatlam: BREND ranglari (zumrad, oltin, marjon…) ikkala rejimda
/// bir xil va `const`; SIRT ranglari (fon, karta, matn, chiziq) rejimga
/// qarab almashadi — ular `static` maydon, [rejim] bilan o'rnatiladi.
/// Nega const emas: 300 dan ortiq joyda to'g'ridan-to'g'ri ishlatiladi;
/// har birini `Theme.of(context)` ga o'tkazishdan ko'ra, palitrani bir
/// joyda almashtirib butun daraxtni qayta chizish arzon va xatosiz.
class AppColors {
  static const emerald = Color(0xFF0E7C66);
  static const emeraldDark = Color(0xFF0A5C4B);
  static const gold = Color(0xFFD4A537);
  static const coral = Color(0xFFE0603A);
  static const success = Color(0xFF2E9E5B);

  // --- Rejimga bog'liq sirt ranglari (yorug' qiymatlar bilan boshlanadi) ---

  /// Ekran foni.
  static Color cream = _yorugCream;

  /// Karta va panellar sirti (yorug'da oq).
  static Color karta = Colors.white;

  /// Asosiy matn.
  static Color ink = _yorugInk;

  /// Ikkinchi darajali matn (yorug'da black54).
  static Color matn2 = Colors.black54;

  /// Uchinchi darajali matn — izoh, yorliq (yorug'da black45).
  static Color matn3 = Colors.black45;

  /// Hoshiya, ajratgich (yorug'da black26).
  static Color chiziq = Colors.black26;

  /// Juda xira hoshiya (yorug'da black12).
  static Color chiziq2 = Colors.black12;

  /// Yumshoq yashil fon (progress fonlari, xira kartalar).
  static Color softGreen = _yorugSoftGreen;

  /// Zumrad MATN rangi — yorug'da to'q zumrad (emeraldDark), qorong'uda
  /// yorqin yalpiz: to'q zumrad qora-yashil fonda ko'rinmay qoladi
  /// (matndagi topilgan so'zlar, urg'uli arabcha, yorliqlar).
  static Color zumradMatn = emeraldDark;

  static bool qorongu = false;

  static const _yorugCream = Color(0xFFF7F3E9);
  static const _yorugInk = Color(0xFF1C2B27);
  static const _yorugSoftGreen = Color(0xFFE3F0EB);

  /// Palitrani rejimga o'rnatadi. Qorong'u tuslar zumrad-qora: qora
  /// emas, ilovaning o'z to'q yashili — oltin va marjon unda yonadi.
  static void rejim(bool q) {
    qorongu = q;
    if (q) {
      cream = const Color(0xFF0B1A17);
      karta = const Color(0xFF14231F);
      ink = const Color(0xFFEEE8D9);
      matn2 = const Color(0xB3EEE8D9);
      matn3 = const Color(0x8CEEE8D9);
      chiziq = const Color(0x38FFFFFF);
      chiziq2 = const Color(0x1FFFFFFF);
      softGreen = const Color(0xFF1C332C);
      zumradMatn = const Color(0xFF6FD8B8);
    } else {
      cream = _yorugCream;
      karta = Colors.white;
      ink = _yorugInk;
      matn2 = Colors.black54;
      matn3 = Colors.black45;
      chiziq = Colors.black26;
      chiziq2 = Colors.black12;
      softGreen = _yorugSoftGreen;
      zumradMatn = emeraldDark;
    }
  }

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
      brightness: AppColors.qorongu ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.emerald,
        brightness: AppColors.qorongu ? Brightness.dark : Brightness.light,
        primary: AppColors.emerald,
        secondary: AppColors.gold,
        surface: AppColors.karta,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
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
    Color? color,
    FontWeight w = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: 'Amiri',
      fontSize: size,
      color: color ?? AppColors.ink,
      fontWeight: w,
      height: 1.4,
    );
  }
}
