import 'dart:math';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../progress.dart';
import '../theme.dart';
import 'sarf_home.dart';
import '../mavzu.dart';
import '../uz_yozuv.dart';
import '../widgets/motion.dart';
import '../widgets/olov.dart';
import '../widgets/wow.dart';
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
import 'nishonlar_ekrani.dart';
import '../nishonlar.dart';
import '../mashq/ultra.dart';
import '../mashq/tovush.dart';
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
    return OchilishSahnasi(
      child: Scaffold(
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
                    const SizedBox(height: 12),
                    // Bo'limlarga tez yo'l — asosiy navigatsiya birinchi
                    // ekranda; to'liq kartalar pastda qoladi.
                    const Reveal(
                      delay: Duration(milliseconds: 60),
                      child: _TezYol(),
                    ),
                    const _NishonTekshiruvchi(),
                    if (!progress.sandiqOchilganBugun) ...[
                      const SizedBox(height: 12),
                      const Reveal(
                        delay: Duration(milliseconds: 75),
                        child: _KunlikSandiq(),
                      ),
                    ],
                    if (progress.olovHimoyalandiBugun) ...[
                      const SizedBox(height: 12),
                      const Reveal(
                        delay: Duration(milliseconds: 80),
                        child: _HimoyaBanner(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Reveal(
                      delay: Duration(milliseconds: 90),
                      child: _XpPanel(),
                    ),
                    const SizedBox(height: 12),
                    const Reveal(
                      delay: Duration(milliseconds: 100),
                      child: _KunlikReja(),
                    ),
                    if (DateTime.now().weekday == DateTime.monday &&
                        progress.otganHaftaNatijasi().$1 > 0) ...[
                      const SizedBox(height: 12),
                      const Reveal(
                        delay: Duration(milliseconds: 104),
                        child: _OtganHafta(),
                      ),
                    ],
                    if (progress.streak > 0 &&
                        !progress.bugunSeriyada &&
                        !progress.kunlikMaqsadBajarildi) ...[
                      const SizedBox(height: 12),
                      const Reveal(
                        delay: Duration(milliseconds: 105),
                        child: _OlovEslatmasi(),
                      ),
                    ],
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
                    const SizedBox(height: 12),
                    const Reveal(
                      delay: Duration(milliseconds: 117),
                      child: _NishonlarKarta(),
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
                        child: _QiyinBanner(
                          soni: progress.qiyinKalitlar.length,
                        ),
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
                          foiz: _foiz([
                            'letter_test',
                            'harakat_test',
                            'ulash_1',
                          ]),
                          title: 'Alifbo (Harflar)',
                          subtitle:
                              'Harf va talaffuz: 28 harf, maxraj, harakatlar',
                          arabic: 'أ ب ت',
                          accent: AppColors.emerald,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AlifboHome(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ModuleCard(
                          foiz: _foiz([
                            for (final l in repo.qiroatLessons) l.completionId,
                          ]),
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
                          subtitle:
                              "Qiyin so'zlarim, lug'at testi, so'z yasash",
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
                          foiz: _foiz([
                            for (final l in repo.nahvLessons)
                              'nahv-${l.book}-${l.num}',
                          ]),
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
                          foiz: _foiz([
                            for (final l in repo.sarfLessons) l.completionId,
                          ]),
                          title: 'Sarf',
                          subtitle:
                              "So'z tuzilishi — vazn, tasrif, fe'l boblari",
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
                    // Faqat Android brauzerida: iPhone yoki kompyuterda
                    // APK taklifi chalg'itadi.
                    if (kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.android) ...[
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
      ),
    );
  }

  /// Ro'yxatdagi darslardan qanchasi o'zlashtirilgan (0..1).
  double? _foiz(List<String> idlar) {
    if (idlar.isEmpty) return null;
    final n = idlar.where(progress.isMastered).length;
    return n / idlar.length;
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
              const Positioned.fill(child: SuzuvchiHarflar()),
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
                      color: AppColors.karta,
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
                              izoh: 'Daraja haqida',
                              onTap: () => _darajaIzohi(context),
                            ),
                            _Chip(
                              belgi: Olov(
                                size: 18,
                                xira: !progress.bugunSeriyada,
                              ),
                              text:
                                  (progress.streak == 0
                                      ? 'Seriya boshlang'
                                      : '${progress.streak} kun ketma-ket') +
                                  (progress.muzlatish > 0
                                      ? '  ·  ${progress.muzlatish} himoya'
                                      : ''),
                              izoh: 'Olov va himoya haqida',
                              onTap: () => _olovOynasi(context),
                              // Bugun hali maqsad bajarilmagan bo'lsa
                              // olov xira — «bugun ham yoqing» ishorasi.
                              color: progress.bugunSeriyada
                                  ? AppColors.coral
                                  : AppColors.coral.withValues(alpha: 0.55),
                            ),
                            const _YozuvTugmasi(),
                            const _MavzuTugmasi(),
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
/// Yorug' ↔ qorong'u tugmasi — yozuv tugmasi yonida, xuddi shu shaklda.
class _MavzuTugmasi extends StatelessWidget {
  const _MavzuTugmasi();

  @override
  Widget build(BuildContext context) {
    final q = Mavzu.instance.qorongu;
    return Tactile(
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: Mavzu.instance.almashtir,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  q ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 15,
                  color: AppColors.goldLight,
                ),
                const SizedBox(width: 5),
                XomText(
                  q ? "Yorug'" : "Qorong'u",
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

/// Daraja zinapoyasi izohi — «Kumush + · 4-daraja» nima ekanini bir
/// bosishda tushuntiradi (atama izohsiz qolmasin).
Future<void> _darajaIzohi(BuildContext context) {
  final p = progress;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.karta,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
              Text(
                'Darajalar qanday ishlaydi',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Har to'g'ri javob ball beradi. Har 100 ball — keyingi daraja. "
            "Hozir: ${p.levelName} (${p.level}-daraja), keyingisigacha "
            "${100 - p.xpInLevel} ball.",
            style: TextStyle(color: AppColors.matn2, height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (i, nom) in Progress.levelNames.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: i + 1 == p.level
                        ? AppColors.gold
                        : (i + 1 < p.level
                              ? AppColors.gold.withValues(alpha: 0.25)
                              : AppColors.softGreen),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${i + 1}. $nom',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: i + 1 == p.level ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final Widget? belgi;

  /// Bosilganda nima bo'lishi (ixtiyoriy) va ekran o'quvchi uchun izoh.
  final VoidCallback? onTap;
  final String? izoh;
  const _Chip({
    required this.text,
    required this.color,
    this.belgi,
    this.onTap,
    this.izoh,
  });

  @override
  Widget build(BuildContext context) {
    final chip = _korinish();
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      label: izoh ?? text,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: chip,
        ),
      ),
    );
  }

  Widget _korinish() {
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

  Color get fg =>
      color == AppColors.gold ? AppColors.goldLight : AppColors.karta;
}

/// XP paneli — raqam yugurib o'sadi, chiziq silliq to'ladi.
/// Bo'limlarga tez yo'l — gorizontal chip qatori. Bo'limlar sahifaning
/// eng pastida edi (3-4 ekran pastda); yangi foydalanuvchi «qayerdan
/// boshlayman» deb qidirardi. Endi bir qarashda va bir bosishda.
class _TezYol extends StatelessWidget {
  const _TezYol();

  @override
  Widget build(BuildContext context) {
    final bolimlar = <(String, String, Color, Widget Function())>[
      ('Alifbo', 'أ', AppColors.emerald, () => const AlifboHome()),
      ('Qiroat', 'اِقْرَأْ', AppColors.teal, () => const QiroatBooksHome()),
      ('Mashqlar', 'تَمَارِين', AppColors.amber, () => const MashqlarHome()),
      ('Nahv', 'نَحْو', AppColors.coral, () => const NahvHome()),
      ('Sarf', 'صَرْف', AppColors.indigo, () => const SarfHome()),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: bolimlar.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (nom, arab, rang, ekran) = bolimlar[i];
          return Semantics(
            button: true,
            label: '$nom bo\'limi',
            child: Tactile(
              child: Material(
                color: AppColors.karta,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ekran()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: rang.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          arab,
                          textDirection: TextDirection.rtl,
                          style: AppTheme.arabic(
                            size: 16,
                            color: rang,
                            w: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          nom,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bosh ekran ochilganda yangi nishon bor-yo'qligini bir marta tekshiradi
/// (masalan, seriya nishoni kun boshida ochiladi) va marosim ko'rsatadi.
class _NishonTekshiruvchi extends StatefulWidget {
  const _NishonTekshiruvchi();

  @override
  State<_NishonTekshiruvchi> createState() => _NishonTekshiruvchiState();
}

class _NishonTekshiruvchiState extends State<_NishonTekshiruvchi> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final yangi = await progress.yangiNishonlar();
      if (yangi.isNotEmpty && mounted) {
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) await nishonOynasi(context, yangi);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Kunlik sandiq kartasi — kunda bir marta, ochilmaguncha bosh ekranda
/// oltin rangda «nafas olib» turadi. Kutish (nima chiqar ekan?) —
/// mukofotning o'zidan ham kuchliroq dofamin manbai.
class _KunlikSandiq extends StatelessWidget {
  const _KunlikSandiq();

  @override
  Widget build(BuildContext context) {
    final bonus = progress.streak.clamp(0, 20);
    return Tactile(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _sandiqOynasi(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.22),
                  AppColors.amber.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Float(
                  amplitude: 3,
                  child: Container(
                    width: 48,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.gold, AppColors.amber],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bugungi sandiq sizni kutmoqda',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        bonus > 0
                            ? "Ichida sovg'a bor · seriya bonusi +$bonus"
                            : "Ichida sovg'a bor — oching!",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.matn2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sandiq oynasi: sovg'a oynani ochish paytida beriladi (bir marta), sandiq
/// bosilganda ko'rsatiladi. Himoya chiqsa alohida satr.
Future<void> _sandiqOynasi(BuildContext context) async {
  final natija = await progress.sandiqniOch(Random());
  if (natija == null || !context.mounted) return;
  final (ball, himoya) = natija;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'sandiq',
    barrierColor: AppColors.deep.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 380),
    transitionBuilder: (context, a, _, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: child,
      ),
    ),
    pageBuilder: (context, _, _) => _SandiqOynasi(ball: ball, himoya: himoya),
  );
}

class _SandiqOynasi extends StatefulWidget {
  final int ball;
  final bool himoya;
  const _SandiqOynasi({required this.ball, required this.himoya});

  @override
  State<_SandiqOynasi> createState() => _SandiqOynasiState();
}

class _SandiqOynasiState extends State<_SandiqOynasi> {
  bool _ochildi = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 22),
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: AppColors.karta,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _ochildi ? 'Bugungi sovg\'a' : 'Kunlik sandiq',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.matn2,
                ),
              ),
              const SizedBox(height: 18),
              XazinaSandigi(
                bonus: widget.ball,
                onOchildi: () {
                  Tovush.sandiq();
                  setState(() => _ochildi = true);
                },
              ),
              if (_ochildi && widget.himoya) ...[
                const SizedBox(height: 10),
                Reveal(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: AppColors.teal,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Olov himoyasi +1',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.teal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (_ochildi)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Rahmat!',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  'Ertaga yana keladi — har kuni bittadan',
                  style: TextStyle(fontSize: 12, color: AppColors.matn3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Olov oynasi: seriya nima, himoya qanday ishlaydi, sotib olish.
Future<void> _olovOynasi(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.karta,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final p = progress;
        final olsaBoladi =
            p.xp >= Progress.muzlatishNarxi &&
            p.muzlatish < Progress.muzlatishChegarasi;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Olov(size: 26),
                  const SizedBox(width: 8),
                  Text(
                    p.streak == 0
                        ? 'Olov hali yoqilmagan'
                        : '${p.streak} kun ketma-ket',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Olov har kuni kunlik maqsad (${Progress.kunlikMaqsad} savol) '
                'bajarilganda yonadi. Bir kun o\'tkazib yuborilsa o\'chadi — '
                'HIMOYA bo\'lsa, o\'sha kun uchun himoya sarflanadi va olov '
                'saqlanib qoladi.',
                style: TextStyle(color: AppColors.matn2, height: 1.45),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < Progress.muzlatishChegarasi; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        i < p.muzlatish
                            ? Icons.shield_rounded
                            : Icons.shield_outlined,
                        size: 30,
                        color: i < p.muzlatish
                            ? AppColors.teal
                            : AppColors.chiziq,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    '${p.muzlatish} / ${Progress.muzlatishChegarasi} himoya',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.matn2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: olsaBoladi
                      ? () async {
                          final ok = await progress.muzlatishSotibOl();
                          if (ok) Haptic.ok();
                        }
                      : null,
                  icon: const Icon(Icons.shield_rounded),
                  label: Text(
                    p.muzlatish >= Progress.muzlatishChegarasi
                        ? 'Himoya to\'la'
                        : 'Himoya olish — ${Progress.muzlatishNarxi} ball',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (!olsaBoladi && p.muzlatish < Progress.muzlatishChegarasi)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Ballingiz: ${p.xp}. Himoya kunlik sandiqdan ham chiqadi.',
                    style: TextStyle(fontSize: 12, color: AppColors.matn3),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

/// «Olov himoyalandi» — kecha o'tkazib yuborilgan, himoya ishlagan kun.
/// Yo'qotish bo'lmagani aytiladi: o'quvchi «hammasi ketdi» demasin.
class _HimoyaBanner extends StatelessWidget {
  const _HimoyaBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.teal, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olov himoyalandi',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  "Kecha o'tkazib yuborgan edingiz — himoya ishladi, "
                  "${progress.streak} kunlik seriya saqlanib qoldi.",
                  style: TextStyle(fontSize: 12.5, color: AppColors.matn2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nishonlar kartasi — nechtasi ochilgani, oxirgi ochilganlar va
/// keyingi maqsad. To'plam «to'ldirilishi» kerakligi ko'rinib turadi.
class _NishonlarKarta extends StatelessWidget {
  const _NishonlarKarta();

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final ochilgan = nishonlar.where((n) => p.nishonOlinganmi(n.id)).toList();
    final keyingi = nishonlar
        .where((n) => !p.nishonOlinganmi(n.id))
        .firstOrNull;
    return Tactile(
      child: Material(
        color: AppColors.karta,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NishonlarEkrani()),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nishonlar  ${ochilgan.length} / ${nishonlar.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final n in ochilgan.reversed.take(5))
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: n.rang.withValues(alpha: 0.18),
                                child: Icon(n.ikon, size: 16, color: n.rang),
                              ),
                            ),
                          if (keyingi != null)
                            Flexible(
                              child: Text(
                                ochilgan.isEmpty
                                    ? 'Birinchisi: ${keyingi.tavsif}'
                                    : 'Keyingisi: ${keyingi.tavsif}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.matn2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _XpPanel extends StatelessWidget {
  const _XpPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.karta,
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
              Expanded(
                child: Text(
                  'Umumiy ball',
                  style: TextStyle(
                    color: AppColors.matn2,
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
            style: TextStyle(color: AppColors.matn3, fontSize: 12.5),
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
        if (soni > 0) ...[
          const SizedBox(height: 10),
          const _BugungiNatija(),
          const _KechaTaqqos(),
        ],
        const SizedBox(height: 12),
        const _Hafta(),
      ],
    );
  }
}

/// Bugungi natija — «bugun nima qildim»: to'g'ri javoblar, aniqlik,
/// bugun olingan ball. Umumiy ball o'sishi sezilmaydi, bugungi «+37»
/// esa ko'z oldida — har kunning o'z yakuni bor, shuning uchun ertaga
/// ham qaytish oson. Faqat bugun kamida bitta javob bo'lsa chiqadi.
/// Kecha bilan taqqoslash — o'sish sezilsin: «kechadan 6 ta ko'p».
/// Kechagi natija hali oshilmagan bo'lsa — aniq, yaqin marra.
class _KechaTaqqos extends StatelessWidget {
  const _KechaTaqqos();

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final (kecha, _, _) = p.kunNatijasi(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    if (kecha == 0) return const SizedBox.shrink();
    final bugun = p.bugungiSavollar;
    final farq = bugun - kecha;
    final String matn;
    final Color rang;
    if (farq > 0) {
      matn = 'Kechadan $farq ta ko\'p — o\'sish!';
      rang = AppColors.success;
    } else if (farq == 0) {
      matn = 'Kechagi bilan teng — yana bittasi o\'tkazadi';
      rang = AppColors.gold;
    } else {
      matn = 'Kecha $kecha ta edi — yana ${-farq} ta va o\'tasiz';
      rang = AppColors.matn2;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            farq > 0 ? Icons.trending_up_rounded : Icons.flag_rounded,
            size: 15,
            color: rang,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              matn,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: rang,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kunlik reja — 4 ta mikro-vazifa, har biri belgilanadi. Ro'yxat
/// «to'lmagan» bo'lsa ong uni tugatishga intiladi (Zeigarnik); hammasi
/// bajarilganda «Kun to'liq» — tinch yakun, ertaga toza boshlash.
class _KunlikReja extends StatelessWidget {
  const _KunlikReja();

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final eslash = p.eslashKerakKalitlar.length;
    final vazifalar = <(String, bool, IconData)>[
      (
        'Kunlik sandiqni ochish',
        p.sandiqOchilganBugun,
        Icons.inventory_2_rounded,
      ),
      (
        'Kunlik maqsad: ${Progress.kunlikMaqsad} savol',
        p.kunlikMaqsadBajarildi,
        Icons.track_changes_rounded,
      ),
      ('Bugungi so\'zni bilib olish', p.bugungiSozBildimmi, Icons.star_rounded),
      (
        eslash == 0
            ? 'Eslash vaqti kelgan so\'zlar — yo\'q'
            : 'Eslash vaqti kelgan $eslash ta so\'z',
        eslash == 0,
        Icons.replay_rounded,
      ),
    ];
    final bajarildi = vazifalar.where((v) => v.$2).length;
    final toliq = bajarildi == vazifalar.length;
    final rang = toliq ? AppColors.success : AppColors.emerald;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.karta,
        borderRadius: BorderRadius.circular(22),
        border: toliq
            ? Border.all(
                color: AppColors.success.withValues(alpha: 0.5),
                width: 1.4,
              )
            : null,
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
          Row(
            children: [
              Icon(
                toliq ? Icons.verified_rounded : Icons.checklist_rounded,
                color: rang,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  toliq ? 'Bugungi reja to\'liq bajarildi!' : 'Bugungi reja',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '$bajarildi / ${vazifalar.length}',
                style: TextStyle(fontWeight: FontWeight.w900, color: rang),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBar(
            value: bajarildi / vazifalar.length,
            height: 6,
            color: rang,
            background: rang.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 10),
          for (final (nom, ok, ikon) in vazifalar)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ok ? AppColors.success : AppColors.chiziq2,
                    ),
                    child: Icon(
                      ok ? Icons.check_rounded : ikon,
                      size: 14,
                      color: ok ? Colors.white : AppColors.matn3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      nom,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: ok ? AppColors.matn3 : AppColors.ink,
                        decoration: ok ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.matn3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Dushanba kuni — o'tgan haftaning yakuni: bir qarashda «qancha qildim».
class _OtganHafta extends StatelessWidget {
  const _OtganHafta();

  @override
  Widget build(BuildContext context) {
    final (savol, togri, ball, kunlar) = progress.otganHaftaNatijasi();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: AppColors.indigo,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O\'tgan hafta yakuni',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '$savol savol · $togri to\'g\'ri · +$ball ball · '
                  '$kunlar kun maqsad bajarildi',
                  style: TextStyle(fontSize: 12.5, color: AppColors.matn2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BugungiNatija extends StatelessWidget {
  const _BugungiNatija();

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final aniqlik = p.bugungiAniqlik;
    final aniqRang = aniqlik >= 80
        ? AppColors.success
        : (aniqlik >= 50 ? AppColors.gold : AppColors.coral);
    final kataklar = <(IconData, Color, String, String)>[
      (
        Icons.check_rounded,
        AppColors.success,
        '${p.bugungiTogri} / ${p.bugungiSavollar}',
        "to'g'ri",
      ),
      (Icons.gps_fixed_rounded, aniqRang, '$aniqlik%', 'aniqlik'),
      (Icons.bolt_rounded, AppColors.gold, '+${p.bugungiBall}', 'bugun ball'),
    ];
    return Row(
      children: [
        for (final (i, (ikon, rang, qiymat, nom)) in kataklar.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: rang.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(ikon, size: 16, color: rang),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          qiymat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            color: rang,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.matn2,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    final (savol, togri, ball) = progress.haftaNatijasi();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 7; i++)
              _kun(_nomlar[i], dushanba.add(Duration(days: i)), bugun),
          ],
        ),
        // Hafta yig'indisi — kunlar alohida raqam, hafta esa bitta yutuq:
        // «bu hafta 120 ta savol» hissi kunlik maqsaddan kattaroq marra.
        if (savol > 0) ...[
          const SizedBox(height: 8),
          Text(
            "Bu hafta: $savol savol · $togri to'g'ri · +$ball ball",
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.matn3,
            ),
          ),
        ],
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
    // Maqsadga yetmagan, lekin mashq qilingan kun — bo'sh doira emas:
    // qancha o'tilgani halqa va raqam bilan ko'rinadi. «Kecha 8 ta
    // qildim» hissi bo'sh doiradan ko'ra qaytishga undaydi.
    final (savol, _, _) = progress.kunNatijasi(kun);
    final qisman = !bajarildi && savol > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (qisman)
          TaraqqiyotHalqasi(
            foiz: savol / Progress.kunlikMaqsad,
            rang: bugunmi ? AppColors.coral : AppColors.success,
            size: 30,
            child: Text(
              '$savol',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: bugunmi ? AppColors.coral : AppColors.success,
              ),
            ),
          )
        else
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
            color: bugunmi ? AppColors.coral : AppColors.matn3,
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
        color: AppColors.karta,
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
          Text(
            'Statistika',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          // Keng ekranda (planshet, brauzer) 3 ustunli nisbatli katak
          // 250 px balandlikda cho'zilib ketardi; endi katak eni ≤ 160 px,
          // balandligi doim 96 px — telefonda 3, kengda 5-6 ustun.
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisExtent: 96,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
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
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.matn2,
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
        color: AppColors.karta,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Unutilishidan oldin qaytaring — 5 daqiqa yetadi',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.matn2,
                        ),
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
  bool get _bildim => progress.bugungiSozBildimmi;

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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tinglash',
            onPressed: () => Tts.instance.speak(e.ovoz, id: e.kalit),
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.emerald),
          ),
          _bildim
              ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
              : FilledButton(
                  onPressed: () {
                    Haptic.ok();
                    progress.bumpWord(e.kalit, true);
                    progress.bugungiSozniBildim();
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

/// Olov eslatmasi — seriya bor, bugun hali yoqilmagan: «yo'qotish»
/// hissi yutuqdan kuchli, shuning uchun eslatma olovni saqlash haqida,
/// jazo haqida emas. Bosilsa oxirgi dars (yoki mashqlar) ochiladi.
class _OlovEslatmasi extends StatelessWidget {
  const _OlovEslatmasi();

  @override
  Widget build(BuildContext context) {
    final qoldi = Progress.kunlikMaqsad - progress.bugungiSavollar;
    return Tactile(
      child: Material(
        color: AppColors.karta,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            final ekran = oxirgiDarsEkrani() ?? const MashqlarHome();
            Navigator.push(context, MaterialPageRoute(builder: (_) => ekran));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.coral.withValues(alpha: 0.5),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                const Olov(size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${progress.streak} kunlik olovni saqlang',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        "Bugun yana $qoldi ta savol — bir raund yetadi",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.matn2,
                        ),
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
        color: AppColors.karta,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        "3+ marta adashilgan — avval o'rgatiladi, keyin so'raladi",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.matn2,
                        ),
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

  /// Modulda o'zlashtirilgan darslar ulushi (0..1); `null` — halqasiz.
  final double? foiz;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.arabic,
    required this.accent,
    this.onTap,
    this.foiz,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    final dark = Color.lerp(accent, Colors.black, 0.28)!;
    final glyph = Text(
      arabic,
      style: AppTheme.arabic(
        size: 26,
        color: AppColors.karta,
        w: FontWeight.w700,
      ),
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
          color: AppColors.karta,
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
                                style: TextStyle(
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
                          style: TextStyle(
                            color: AppColors.matn2,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (foiz != null && foiz! > 0) ...[
                    TaraqqiyotHalqasi(foiz: foiz!, rang: accent, size: 42),
                    const SizedBox(width: 8),
                  ],
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
                    color: AppColors.karta,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.android,
                    color: AppColors.emerald,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
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
                        'Android · APK, 42 MB — brauzersiz ishlatasiz',
                        style: TextStyle(color: AppColors.matn2, fontSize: 13),
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
