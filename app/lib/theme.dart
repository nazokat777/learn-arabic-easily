import 'package:flutter/material.dart';

/// Ilova ranglari — NEON + GLASS: yorqin binafsha, pushti, feruza,
/// yashil; sirtlar yarim shaffof «shisha» (oq/qora tuman ustida).
/// Nomlar tarixiy (emerald, gold…) — 300+ joyda ishlatiladi, shuning
/// uchun qiymatlari almashtirildi, nomlari emas.
///
/// Ikki qatlam: BREND ranglari (zumrad, oltin, marjon…) ikkala rejimda
/// bir xil va `const`; SIRT ranglari (fon, karta, matn, chiziq) rejimga
/// qarab almashadi — ular `static` maydon, [rejim] bilan o'rnatiladi.
/// Nega const emas: 300 dan ortiq joyda to'g'ridan-to'g'ri ishlatiladi;
/// har birini `Theme.of(context)` ga o'tkazishdan ko'ra, palitrani bir
/// joyda almashtirib butun daraxtni qayta chizish arzon va xatosiz.
class AppColors {
  static const emerald = Color(0xFF7C3AED);
  static const emeraldDark = Color(0xFF5B21B6);
  static const gold = Color(0xFFF59E0B);
  static const coral = Color(0xFFEC4899);
  static const success = Color(0xFF16A34A);

  // --- Rejimga bog'liq sirt ranglari (yorug' qiymatlar bilan boshlanadi) ---

  /// Ekran foni.
  static Color cream = _yorugCream;

  /// Karta va panellar sirti (yorug'da oq).
  static Color karta = const Color(0xB8FFFFFF); // shisha

  /// Asosiy matn.
  static Color ink = _yorugInk;

  /// Ikkinchi darajali matn (yorug'da black54).
  static Color matn2 = Colors.black54;

  /// Uchinchi darajali matn — izoh, yorliq (yorug'da black45).
  static Color matn3 = const Color(0x99000000);

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

  static const _yorugCream = Color(0xFFF3F0FF);
  static const _yorugInk = Color(0xFF1E1B3A);
  static const _yorugSoftGreen = Color(0xFFEDE9FE);

  /// Palitrani rejimga o'rnatadi. Qorong'u tuslar zumrad-qora: qora
  /// emas, ilovaning o'z to'q yashili — oltin va marjon unda yonadi.
  static void rejim(bool q) {
    qorongu = q;
    if (q) {
      cream = const Color(0xFF0E0B1F);
      karta = const Color(0x99231C45); // to'q shisha
      ink = const Color(0xFFEDE9FE);
      matn2 = const Color(0xB3EDE9FE);
      matn3 = const Color(0xA6EDE9FE);
      chiziq = const Color(0x38FFFFFF);
      chiziq2 = const Color(0x1FFFFFFF);
      softGreen = const Color(0xFF2A2152);
      zumradMatn = const Color(0xFFC4B5FD);
    } else {
      cream = _yorugCream;
      karta = const Color(0xB8FFFFFF);
      ink = _yorugInk;
      matn2 = Colors.black54;
      matn3 = const Color(0x99000000);
      chiziq = Colors.black26;
      chiziq2 = Colors.black12;
      softGreen = _yorugSoftGreen;
      zumradMatn = emeraldDark;
    }
  }

  // Har modulning o'z urg'u rangi — hammasi bir xil yashil bo'lsa ekran
  // «bir tekis» va zerikarli tuyuladi; farqli ranglar ko'zga yo'l ko'rsatadi.
  static const teal = Color(0xFF06B6D4);
  static const indigo = Color(0xFF4F46E5);
  static const amber = Color(0xFFF97316);

  /// Hero va chuqur fonlar uchun eng to'q yashil.
  static const deep = Color(0xFF1E1B4B);

  /// Oltinning yorug' tusi — yaltiroq chiziqlar va urg'ular uchun.
  static const goldLight = Color(0xFFFCD34D);
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
    // Shisha karta: yarim shaffof sirt, oq yaltiroq hoshiya, binafsha nur.
    final shisha = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: AppColors.qorongu
            ? const Color(0x33C4B5FD)
            : const Color(0xB3FFFFFF),
        width: 1.2,
      ),
    );
    return base.copyWith(
      cardTheme: CardThemeData(
        color: AppColors.karta,
        elevation: 6,
        shadowColor: AppColors.emerald.withValues(alpha: 0.18),
        shape: shisha,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 6,
          shadowColor: AppColors.emerald.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.karta,
          side: BorderSide(
            color: AppColors.emerald.withValues(alpha: 0.45),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: base.textTheme.apply(fontFamily: 'Nunito'),
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
  ///
  /// [height] 1.9: Amiri'da harakatlar (ayniqsa ustki: fatha, shadda,
  /// tanvin) qator balandligidan chiqib ketadi — 1.4 da ko'p qatorli
  /// matnda pastki qatorning ustki harakatlari ustki qatorning ostki
  /// harakatlariga (kasra) yopishib, o'qib bo'lmas edi (2026-09-15).
  static TextStyle arabic({
    double size = 40,
    Color? color,
    FontWeight w = FontWeight.w600,
    double height = 1.9,
  }) {
    return TextStyle(
      fontFamily: 'Amiri',
      fontSize: size,
      color: color ?? AppColors.ink,
      fontWeight: w,
      height: height,
    );
  }
}
