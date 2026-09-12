import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../progress.dart';
import '../theme.dart';
import 'sarf_home.dart';
import '../uz_yozuv.dart';
import '../widgets/motion.dart';
import '../widgets/olov.dart';
import '../mashq/bank.dart';
import '../mashq/element.dart';
import '../mashq/mashq_ekran.dart';
import '../rasm.dart';
import '../services/tts.dart';
import '../widgets/ornament.dart';
import 'alifbo_home.dart';
import 'davom.dart';
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
                  if (oxirgiDarsEkrani() != null) ...[
                    const SizedBox(height: 12),
                    Reveal(
                      delay: const Duration(milliseconds: 110),
                      child: _DavomKarta(nom: progress.oxirgiDarsNomi ?? ''),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Reveal(
                    delay: Duration(milliseconds: 115),
                    child: _Statistika(),
                  ),
                  if (progress.eslashKerakKalitlar.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Reveal(
                      delay: const Duration(milliseconds: 118),
                      child: _EslashKartasi(
                        soni: progress.eslashKerakKalitlar.length,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Reveal(
                    delay: Duration(milliseconds: 122),
                    child: _BugungiSoz(),
                  ),
                  if (progress.qiyinKalitlar.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Reveal(
                      delay: const Duration(milliseconds: 120),
                      child: _QiyinBanner(soni: progress.qiyinKalitlar.length),
                    ),
                  ],
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
                            'Harf va talaffuz: 28 harf, maxraj, harakatlar',
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
                        subtitle: "Qiyin so'zlarim, lug'at testi, so'z yasash",
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
                      _ModuleCard(
                        title: 'Sarf',
                        subtitle: "So'z tuzilishi — vazn, tasrif, fe'l boblari",
                        arabic: 'صَرْف',
                        accent: AppColors.indigo,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SarfHome()),
                        ),
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
                              belgi: Olov(
                                size: 18,
                                xira: !progress.bugunSeriyada,
                              ),
                              text: progress.streak == 0
                                  ? 'Seriya boshlang'
                                  : '${progress.streak} kun ketma-ket',
                              // Bugun hali maqsad bajarilmagan bo'lsa
                              // olov xira — «bugun ham yoqing» ishorasi.
                              color: progress.bugunSeriyada
                                  ? AppColors.coral
                                  : AppColors.coral.withValues(alpha: 0.55),
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
  final Widget? belgi;
  const _Chip({required this.text, required this.color, this.belgi});

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
          if (belgi != null) ...[belgi!, const SizedBox(width: 5)],
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
          const SizedBox(height: 14),
          const _KunlikMaqsad(),
        ],
      ),
    );
  }
}

/// Kunlik maqsad qatori — «Bugun: 12 / 20 savol».
///
/// Har kuni qaytib keltiruvchi eng kuchli mexanizm: marra yaqin,
/// aniq va bugungi. Bajarilganda yashil belgi, ertaga yana noldan.
class _KunlikMaqsad extends StatelessWidget {
  const _KunlikMaqsad();

  /// Marraga yaqinlashganda matn qizg'inlashadi — «goal gradient»:
  /// odam marra yaqinida tezlashadi, shuni ko'rsatib qo'yamiz.
  static String _maqsadMatni(int soni) {
    final qoldi = Progress.kunlikMaqsad - soni;
    if (soni == 0) return 'Bugungi maqsad: ${Progress.kunlikMaqsad} savol';
    if (qoldi <= 3) return 'Faqat $qoldi ta qoldi — olovni yoqing!';
    if (qoldi <= 8) return 'Yarmidan oshdingiz: $qoldi ta qoldi';
    return 'Bugungi maqsad: $soni / ${Progress.kunlikMaqsad} savol';
  }

  @override
  Widget build(BuildContext context) {
    final soni = progress.bugungiSavollar;
    final bajarildi = progress.kunlikMaqsadBajarildi;
    final rang = bajarildi ? AppColors.success : AppColors.coral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              bajarildi
                  ? Icons.check_circle_rounded
                  : Icons.track_changes_rounded,
              size: 18,
              color: rang,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                bajarildi ? 'Bugungi maqsad bajarildi!' : _maqsadMatni(soni),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: rang,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBar(
          value: (soni / Progress.kunlikMaqsad).clamp(0, 1).toDouble(),
          height: 8,
          color: rang,
          background: rang.withValues(alpha: 0.12),
        ),
        const SizedBox(height: 12),
        const _Hafta(),
      ],
    );
  }
}

/// Oxirgi yetti kun — maqsad bajarilgan kunlar to'lgan doira.
///
/// Seriya raqami mavhum, yetti doira esa ko'z oldida: «shanba bo'sh
/// qolibdi» degan his keyingi haftani tekis qiladi. Bugungi kun
/// hoshiya bilan ajratiladi.
class _Hafta extends StatelessWidget {
  const _Hafta();

  static const _nomlar = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  Widget build(BuildContext context) {
    final bugun = DateTime.now();
    // Haftaning dushanbasidan boshlab — kalendar kabi o'qiladi.
    final dushanba = DateTime(
      bugun.year,
      bugun.month,
      bugun.day - (bugun.weekday - 1),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          _kun(_nomlar[i], dushanba.add(Duration(days: i)), bugun),
      ],
    );
  }

  Widget _kun(String nom, DateTime kun, DateTime bugun) {
    final bajarildi = progress.maqsadBajarilganKun(kun);
    final bugunmi =
        kun.year == bugun.year &&
        kun.month == bugun.month &&
        kun.day == bugun.day;
    final kelajak = kun.isAfter(bugun) && !bugunmi;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: kExpoOut,
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bajarildi
                ? AppColors.success
                : AppColors.success.withValues(alpha: kelajak ? 0.05 : 0.12),
            border: bugunmi
                ? Border.all(color: AppColors.coral, width: 2)
                : null,
          ),
          child: bajarildi
              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          nom,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bugunmi ? FontWeight.w900 : FontWeight.w600,
            color: bugunmi ? AppColors.coral : Colors.black45,
          ),
        ),
      ],
    );
  }
}

/// Statistika — raqamlar sanab chiqadi, har biri o'z rangi bilan.
///
/// O'quvchi yo'lini raqamda ko'radi: yodlangan so'zlar, o'zlashtirilgan
/// darslar, aniqlik, rekord seriya, maqsad bajarilgan kunlar. Raqam
/// sanab chiqishi (CountUp) — «o'sish» hissi, statik raqam bermaydi.
class _Statistika extends StatelessWidget {
  const _Statistika();

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final kataklar = <(IconData, Color, int, String, String)>[
      (
        Icons.spellcheck_rounded,
        AppColors.emerald,
        p.yodlanganSoni,
        '',
        "yodlangan so'z",
      ),
      (
        Icons.verified_rounded,
        AppColors.gold,
        p.ozlashtirilganDarslar,
        '',
        "o'zlashtirilgan dars",
      ),
      (Icons.gps_fixed_rounded, AppColors.teal, p.aniqlikFoizi, '%', 'aniqlik'),
      (
        Icons.local_fire_department_rounded,
        AppColors.coral,
        p.rekordKombo,
        '',
        'rekord seriya',
      ),
      (
        Icons.event_available_rounded,
        AppColors.success,
        p.maqsadKunlariSoni,
        '',
        'maqsad bajarilgan kun',
      ),
      (
        Icons.question_answer_rounded,
        AppColors.indigo,
        p.jamiJavoblar,
        '',
        'jami javob',
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistika',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              for (final (ikon, rang, qiymat, qoshimcha, nom) in kataklar)
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  decoration: BoxDecoration(
                    color: rang.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(ikon, color: rang, size: 20),
                      const SizedBox(height: 4),
                      CountUp(
                        value: qiymat,
                        suffix: qoshimcha,
                        duration: const Duration(milliseconds: 900),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: rang,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        nom,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «Eslash vaqti» — oraliqli takror (Ebbinghaus): yodlangan so'z
/// unutilishidan sal oldin qaytariladi. Har kuni kichik, aniq vazifa —
/// qaytishning eng pedagogik sababi.
class _EslashKartasi extends StatelessWidget {
  final int soni;
  const _EslashKartasi({required this.soni});

  @override
  Widget build(BuildContext context) {
    return Tactile(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            final kalitlar = progress.eslashKerakKalitlar.toSet();
            final elementlar = MashqBank.kalitlarBoyicha(kalitlar);
            if (elementlar.isEmpty) return;
            final darsniki = elementlar.take(20).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MashqEkran(
                  sarlavha: 'Eslash vaqti',
                  darsniki: darsniki,
                  oldingilar: MashqBank.qiyinHavzasi(darsniki),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.indigo.withValues(alpha: 0.4),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.indigo.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eslash vaqti keldi: $soni so\'z',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      const Text(
                        'Unutilishidan oldin qaytaring — 5 daqiqa yetadi',
                        style: TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.indigo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bugungi so'z — darsni ochmasdan ham bitta so'z: ko'rish, eshitish,
/// «bildim». Kunlik maqsadga 1 savol qo'shiladi — «boshlab qo'ydim»
/// hissi eng kichik qadamdan tug'iladi.
class _BugungiSoz extends StatefulWidget {
  const _BugungiSoz();

  @override
  State<_BugungiSoz> createState() => _BugungiSozState();
}

class _BugungiSozState extends State<_BugungiSoz> {
  static MashqElement? _soz;
  static int _sozKuni = -1;
  bool _bildim = false;

  MashqElement? _bugungi() {
    final kun = DateTime.now().difference(DateTime(1970)).inDays;
    if (_sozKuni == kun) return _soz;
    // Qiroat lug'atidan — konkret, qisqa; kun raqami tanlaydi.
    final havza = <MashqElement>[
      for (final l in repo.qiroatLessons) ...MashqBank.qiroatDars(l),
    ];
    if (havza.isEmpty) return null;
    _soz = havza[kun % havza.length];
    _sozKuni = kun;
    return _soz;
  }

  @override
  Widget build(BuildContext context) {
    final e = _bugungi();
    if (e == null) return const SizedBox.shrink();
    final rasm = Rasm.topish(e.uz);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "BUGUNGI SO'Z",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (rasm != null) ...[
                      Text(rasm, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                    ],
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        e.ar,
                        style: AppTheme.arabic(
                          size: 28,
                          color: AppColors.emerald,
                          w: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  e.uz,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Tts.instance.speak(e.ovoz, id: e.kalit),
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.emerald),
          ),
          _bildim
              ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
              : FilledButton(
                  onPressed: () {
                    Haptic.ok();
                    progress.bumpWord(e.kalit, true);
                    setState(() => _bildim = true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Bildim',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
        ],
      ),
    );
  }
}

/// «Davom etish» — oxirgi ochilgan darsga bir bosishda qaytish.
///
/// Eng katta ishqalanish «qayerda qolgan edim?» degan qidiruv; bu karta
/// uni yo'q qiladi. Faqat oxirgi dars ma'lum bo'lganda chiqadi.
class _DavomKarta extends StatelessWidget {
  final String nom;
  const _DavomKarta({required this.nom});

  @override
  Widget build(BuildContext context) {
    return Tactile(
      child: Material(
        color: AppColors.emerald,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            final ekran = oxirgiDarsEkrani();
            if (ekran == null) return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => ekran));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Davom etish',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Qiyin so'zlarim» — bosh ekranda, faqat ro'yxat bo'sh bo'lmaganda.
///
/// O'quvchi qoqilayotgan so'zlarini qidirib yurmasin: ilova ochilishi
/// bilan «mana shu N ta so'z sizni kutyapti» deb ko'rsatadi. Ro'yxat
/// bo'shaganda banner o'zi yo'qoladi — bu ham mukofot.
class _QiyinBanner extends StatelessWidget {
  final int soni;
  const _QiyinBanner({required this.soni});

  @override
  Widget build(BuildContext context) {
    return Tactile(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => qiyinMashqiniOch(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.coral.withValues(alpha: 0.45),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Qiyin so'zlarim: $soni ta",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      const Text(
                        "3+ marta adashilgan — avval o'rgatiladi, keyin so'raladi",
                        style: TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.coral),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modul kartochkasi — rangli soya, gradient ikonka, suzuvchi harf.
class _ModuleCard extends StatelessWidget {
  final String title, subtitle, arabic;
  final Color accent;
  final VoidCallback? onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.arabic,
    required this.accent,
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

    return Tactile(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.16),
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
            onTap: onTap,
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
                    child: Center(child: Float(amplitude: 3, child: glyph)),
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
                      Icons.arrow_forward_rounded,
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
