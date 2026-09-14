import 'package:flutter/material.dart' hide Text;

import '../main.dart';
import '../mashq/tovush.dart';
import '../progress.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import '../widgets/uz_text.dart';

/// Hafta hisoboti — yangi hafta boshlanganda bir marta tantanali oyna:
/// o'tgan haftaning 7 kuni ustunlarda, eng yaxshi kun, aniqlik, ball va
/// undan oldingi hafta bilan taqqos. «Men qancha qildim» ni ko'rish —
/// o'zini o'zi mukofotlash; o'sish (↑) ko'rinsa, davom etish istagi kuchayadi.
/// Faqat o'tgan haftada faollik bo'lsa chiqadi; bo'sh hafta uchun ta'na yo'q.
Future<void> haftaHisobotiOynasi(BuildContext context) async {
  Tovush.daraja();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.karta,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => const _HaftaHisoboti(),
  );
  await progress.haftaHisobotiniKordim();
}

class _HaftaHisoboti extends StatelessWidget {
  const _HaftaHisoboti();

  static const _nomlar = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final kunlar = p.otganHaftaKunlari();
    final (savol, togri, ball, maqsadKun) = p.otganHaftaNatijasi();
    final (oSavol, _, oBall) = p.undanOldingiHaftaNatijasi();
    final aniqlik = savol == 0 ? 0 : (togri * 100 / savol).round();
    final engKop = kunlar.map((k) => k.$2).fold(0, (a, b) => a > b ? a : b);
    final engYaxshi = kunlar.indexWhere((k) => k.$2 == engKop);
    final faolKun = kunlar.where((k) => k.$2 > 0).length;
    final haftaYutildi = maqsadKun >= Progress.haftaMaqsadi;

    // Taqqos: o'tgan haftadan oldingi hafta bo'lsa — o'sish/pasayish.
    String? taqqos;
    Color taqqosRang = AppColors.matn3;
    if (oSavol > 0) {
      final farq = ball - oBall;
      if (farq > 0) {
        taqqos = 'Oldingi haftadan +$farq ball ko\'p — o\'sish!';
        taqqosRang = AppColors.success;
      } else if (farq < 0) {
        taqqos = 'Oldingi haftadan ${-farq} ball kam — bu hafta qaytaramiz.';
        taqqosRang = AppColors.coral;
      } else {
        taqqos = 'Oldingi hafta bilan teng — barqaror.';
      }
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            18,
            22,
            22 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    haftaYutildi
                        ? Icons.emoji_events_rounded
                        : Icons.calendar_month_rounded,
                    color: AppColors.gold,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      haftaYutildi
                          ? 'Hafta yutildi!'
                          : 'O\'tgan hafta hisoboti',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                haftaYutildi
                    ? '$maqsadKun kun maqsad bajarildi — '
                          'haftalik marraga yetdingiz.'
                    : '$faolKun kun mashq qildingiz, $maqsadKun kunida '
                          'maqsad bajarildi.',
                style: TextStyle(color: AppColors.matn2, height: 1.4),
              ),
              const SizedBox(height: 16),
              // 7 ustun — har kunning savollari; eng yaxshi kun oltin.
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, (kun, s, _, _)) in kunlar.indexed) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _Ustun(
                          nom: _nomlar[kun.weekday - 1],
                          qiymat: s,
                          ulush: engKop == 0 ? 0 : s / engKop,
                          engYaxshi: i == engYaxshi && s > 0,
                          maqsad: p.maqsadBajarilganKun(kun),
                          kechikish: Duration(milliseconds: 80 * i),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Katak(
                    ikon: Icons.help_outline_rounded,
                    rang: AppColors.indigo,
                    qiymat: savol,
                    nom: 'savol',
                  ),
                  const SizedBox(width: 8),
                  _Katak(
                    ikon: Icons.gps_fixed_rounded,
                    rang: aniqlik >= 80
                        ? AppColors.success
                        : (aniqlik >= 50 ? AppColors.gold : AppColors.coral),
                    qiymat: aniqlik,
                    suffix: '%',
                    nom: 'aniqlik',
                  ),
                  const SizedBox(width: 8),
                  _Katak(
                    ikon: Icons.bolt_rounded,
                    rang: AppColors.gold,
                    qiymat: ball,
                    prefix: '+',
                    nom: 'ball',
                  ),
                ],
              ),
              if (taqqos != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      taqqosRang == AppColors.success
                          ? Icons.trending_up_rounded
                          : (taqqosRang == AppColors.coral
                                ? Icons.trending_down_rounded
                                : Icons.trending_flat_rounded),
                      size: 18,
                      color: taqqosRang,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        taqqos,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: taqqosRang,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (engYaxshi >= 0 && engKop > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Eng yaxshi kun: ${_toliqNom(kunlar[engYaxshi].$1.weekday)} '
                        '— $engKop savol',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.matn2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Haptic.ok();
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Yangi haftani boshlaymiz',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (haftaYutildi)
          const Positioned.fill(
            child: IgnorePointer(child: Confetti(count: 70)),
          ),
      ],
    );
  }

  static String _toliqNom(int weekday) => const [
    'dushanba',
    'seshanba',
    'chorshanba',
    'payshanba',
    'juma',
    'shanba',
    'yakshanba',
  ][weekday - 1];
}

/// Bitta kun ustuni — pastdan o'sib chiqadi, eng yaxshisi oltin, maqsad
/// bajarilgan kun ostida belgi.
class _Ustun extends StatelessWidget {
  final String nom;
  final int qiymat;
  final double ulush;
  final bool engYaxshi;
  final bool maqsad;
  final Duration kechikish;
  const _Ustun({
    required this.nom,
    required this.qiymat,
    required this.ulush,
    required this.engYaxshi,
    required this.maqsad,
    required this.kechikish,
  });

  @override
  Widget build(BuildContext context) {
    final rang = engYaxshi
        ? AppColors.gold
        : (qiymat > 0 ? AppColors.emerald : AppColors.chiziq);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (qiymat > 0)
          Text(
            '$qiymat',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: rang,
            ),
          ),
        const SizedBox(height: 3),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ulush.clamp(0.06, 1.0)),
              duration: const Duration(milliseconds: 700) + kechikish,
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                heightFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    color: rang.withValues(alpha: qiymat > 0 ? 0.9 : 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          nom,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: maqsad ? AppColors.success : AppColors.matn3,
          ),
        ),
        Icon(
          maqsad ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 12,
          color: maqsad ? AppColors.success : AppColors.chiziq,
        ),
      ],
    );
  }
}

class _Katak extends StatelessWidget {
  final IconData ikon;
  final Color rang;
  final int qiymat;
  final String nom;
  final String prefix;
  final String suffix;
  const _Katak({
    required this.ikon,
    required this.rang,
    required this.qiymat,
    required this.nom,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: rang.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(ikon, size: 18, color: rang),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (prefix.isNotEmpty)
                  Text(
                    prefix,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: rang,
                    ),
                  ),
                CountUp(
                  value: qiymat,
                  suffix: suffix,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: rang,
                  ),
                ),
              ],
            ),
            Text(nom, style: TextStyle(fontSize: 11, color: AppColors.matn3)),
          ],
        ),
      ),
    );
  }
}
