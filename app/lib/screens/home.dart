import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../theme.dart';
import '../uz_yozuv.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import 'alifbo_home.dart';
import 'mashqlar_home.dart';
import 'nahv_home.dart';
import 'qiroat_lessons.dart';

/// Bosh ekran — ilovaning «yuzi».
///
/// Dizayn maqsadi: ochilganda birinchi soniyalarda «bu jiddiy, sifatli
/// mahsulot» degan his bersin. Buning uchun uchta qatlam ishlatiladi:
///   * chuqurlik — rangli soyalar, gradientlar, orqada sekin suzuvchi
///     aurora dog'lari;
///   * harakat — elementlar to'lqin bo'lib chiqadi (stagger), raqamlar
///     yugurib o'sadi, hero ustidan vaqti-vaqti bilan yaltiroq o'tadi;
///   * ierarxiya — bitta katta hero, bitta XP paneli, keyin modullar.
/// Kontent o'zgarmagan — faqat tajriba.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Orqa fon: sekin suzuvchi yumshoq dog'lar. Ekran «tirik» tuyuladi,
          // lekin diqqatni tortmaydi — shaffofligi juda past.
          const Positioned.fill(
            child: Aurora(
              colors: [AppColors.emerald, AppColors.gold, AppColors.teal],
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) => ListView(
                // Tepada biroz nafas — hero ekran chetiga yopishib qolmasin.
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
                children: [
                  const Reveal(child: _Hero()),
                  const SizedBox(height: 16),
                  const Reveal(
                    delay: Duration(milliseconds: 90),
                    child: _XpPanel(),
                  ),
                  const SizedBox(height: 26),
                  Reveal(
                    delay: const Duration(milliseconds: 160),
                    child: Row(
                      children: [
                        Text(
                          "Bo'limlar",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Stagger(
                    start: const Duration(milliseconds: 220),
                    step: const Duration(milliseconds: 85),
                    children: [
                      _ModuleCard(
                        title: 'Alifbo (Harflar)',
                        subtitle:
                            'Harf va talaffuz: 28 harf, махраж, harakatlar',
                        arabic: 'أ ب ت',
                        accent: AppColors.emerald,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AlifboHome()),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ModuleCard(
                        title: 'Mabdaul qiroat',
                        subtitle: "O'qish asosi — 1, 2 va 3-kitob (169 dars)",
                        arabic: 'اِقْرَأْ',
                        accent: AppColors.teal,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QiroatBooksHome(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ModuleCard(
                        title: 'Mashqlar',
                        subtitle: "Lug'at testi va so'z yasash o'yini",
                        arabic: 'تَمَارِين',
                        accent: AppColors.amber,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MashqlarHome(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ModuleCard(
                        title: 'Nahv',
                        subtitle:
                            "Jumla tuzilishi — «الدروس النحوية» kitobidan",
                        arabic: 'نَحْو',
                        accent: AppColors.coral,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NahvHome()),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _ModuleCard(
                        title: 'Sarf',
                        subtitle: "So'z tuzilishi — vazn, tasrif, fe'l boblari",
                        arabic: 'صَرْف',
                        accent: AppColors.indigo,
                        enabled: false,
                      ),
                    ],
                  ),
                  // Saytda ochganlar uchun: ko'pchilik ilovani telefonga
                  // o'rnatmoqchi, lekin APK'ni qayerdan olishni bilmaydi.
                  if (kIsWeb) ...[
                    const SizedBox(height: 22),
                    const Reveal(
                      delay: Duration(milliseconds: 700),
                      child: _ApkBanner(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero — to'q yashil gradient, suzuvchi katta harf, oltin urg'ular.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.35),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Shine(
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 20, 22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.deep,
                AppColors.emeraldDark,
                AppColors.emerald,
              ],
              stops: [0, 0.55, 1],
            ),
          ),
          child: Stack(
            children: [
              // Girih (8 uchli yulduz) naqshi — islomiy ilovaning imzosi.
              // Juda xira: fon, mazmun emas.
              const Positioned.fill(
                child: GirihPattern(opacity: 0.07, cell: 52),
              ),
              // Orqa fondagi xira xattotlik — chuqurlik beradi.
              Positioned(
                right: -6,
                bottom: -26,
                child: Opacity(
                  opacity: 0.08,
                  child: Text(
                    'اِقْرَأْ',
                    style: AppTheme.arabic(
                      size: 96,
                      color: Colors.white,
                      w: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Oltin nur — yuqori o'ngda.
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.35),
                        AppColors.gold.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Float(
                    amplitude: 5,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.goldLight, AppColors.gold],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'ع',
                          style: AppTheme.arabic(
                            size: 44,
                            color: AppColors.deep,
                            w: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Salomlashish — kunning vaqtiga qarab. Kichik narsa,
                        // lekin ilova «shaxsan menga» gapirayotgandek tuyuladi.
                        Text(
                          _salom(),
                          style: TextStyle(
                            color: AppColors.goldLight.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Arab tilini oson\no'rganamiz",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 21,
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(
                              text:
                                  '${progress.levelName} · '
                                  '${progress.level}-daraja',
                              color: AppColors.gold,
                            ),
                            _Chip(
                              icon: Icons.local_fire_department_rounded,
                              text: '${progress.streak} kun',
                              color: AppColors.coral,
                            ),
                            const _YozuvTugmasi(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lotin ↔ kirill almashtirgichi — daraja va seriya chiplari yonida.
///
/// Yozuvi doim O'TILADIGAN yozuvda: lotin rejimida «Кирилл» deb turadi,
/// bosilsa kirillga o'tadi. Shu sababli o'quvchi tugmani o'qiy oladi —
/// hatto hozirgi yozuvni qiynalib o'qiyotgan bo'lsa ham.
///
/// Nega hero'ning burchagida emas: u yerda `Stack` ning ustki qatlamlari
/// (oltin nur, sarlavha qatori) bosishni yutib yuborardi — tugma ko'rinib
/// turib, bosilmasdi. Chiplar qatorida esa hech narsa ustida turmaydi.
class _YozuvTugmasi extends StatelessWidget {
  const _YozuvTugmasi();

  @override
  Widget build(BuildContext context) {
    // Tugmaning o'z yozuvi ham darrov almashishi kerak — shuning uchun u
    // ham tinglaydi (matnlar bilan bir xil sabab: hero const shox ichida).
    return ListenableBuilder(
      listenable: UzYozuv.instance,
      builder: (context, _) => _tugma(UzYozuv.instance.kirill),
    );
  }

  Widget _tugma(bool kirill) {
    return Tactile(
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: UzYozuv.instance.almashtir,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.translate_rounded,
                  size: 15,
                  color: AppColors.goldLight,
                ),
                const SizedBox(width: 5),
                XomText(
                  kirill ? 'Lotin' : 'Кирилл',
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kun vaqtiga qarab salomlashish.
String _salom() {
  final h = DateTime.now().hour;
  if (h < 5) return 'Xayrli tun';
  if (h < 12) return 'Xayrli tong';
  if (h < 18) return 'Xayrli kun';
  return 'Xayrli kech';
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const _Chip({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Color get fg => color == AppColors.gold ? AppColors.goldLight : Colors.white;
}

/// XP paneli — raqam yugurib o'sadi, chiziq silliq to'ladi.
class _XpPanel extends StatelessWidget {
  const _XpPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  'Umumiy ball',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              CountUp(
                value: progress.xp,
                suffix: ' ball',
                style: const TextStyle(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBar(
            value: progress.levelProgress,
            height: 12,
            color: AppColors.gold,
            background: AppColors.softGreen,
          ),
          const SizedBox(height: 8),
          Text(
            'Keyingi darajagacha: ${100 - progress.xpInLevel} ball',
            style: const TextStyle(color: Colors.black45, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

/// Modul kartochkasi — rangli soya, gradient ikonka, suzuvchi harf.
class _ModuleCard extends StatelessWidget {
  final String title, subtitle, arabic;
  final Color accent;
  final bool enabled;
  final VoidCallback? onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.arabic,
    required this.accent,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    final dark = Color.lerp(accent, Colors.black, 0.28)!;
    final glyph = Text(
      arabic,
      style: AppTheme.arabic(size: 26, color: Colors.white, w: FontWeight.w700),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Tactile(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: enabled ? 0.16 : 0.05),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, dark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: enabled
                            ? Float(amplitude: 3, child: glyph)
                            : glyph,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    color: AppColors.ink,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (!enabled) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.lock_rounded,
                                  size: 15,
                                  color: accent,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        enabled
                            ? Icons.arrow_forward_rounded
                            : Icons.hourglass_empty_rounded,
                        size: 18,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// APK yuklab olish sahifasini ochadi. Sahifa saytning o'zida turadi
/// (`apk.html`), shuning uchun manzilni joriy manzilga nisbatan olamiz —
/// sayt boshqa domenga ko'chsa ham ishlayveradi.
void launchApkPage() {
  launchUrl(Uri.base.resolve('apk.html'), webOnlyWindowName: '_blank');
}

/// «Telefonga o'rnatish» taklifi — faqat brauzerda ko'rinadi.
class _ApkBanner extends StatelessWidget {
  const _ApkBanner();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Tactile(
      child: Material(
        color: AppColors.softGreen,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: launchApkPage,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.android,
                    color: AppColors.emerald,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Telefonga o'rnatish",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Android uchun APK — brauzersiz ishlatasiz',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.download_rounded, color: AppColors.emerald),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
