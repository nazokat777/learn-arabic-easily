import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import '../widgets/uz_text.dart';

/// Mashqning MUKOFOT qatlami: maqtov, portlash, uchuvchi ball, kombo olovi,
/// yulduzlar va raund bekati.
///
/// Nega alohida fayl: bu widgetlar o'rganish mantig'iga tegmaydi, ular
/// faqat «to'g'ri javob — yoqimli» degan bog'lanishni miyaga o'rnatadi.
/// Xotira ilmi bo'yicha mukofot QISQA (bir soniya ichida), KUTILMAGAN
/// (har safar bir xil emas) va HARAKATGA BOG'LIQ (aynan bosilgan joydan
/// chiqadi) bo'lsa, o'quvchi mashqni tashlamaydi.

/// Maqtov so'zlari — har safar boshqacha. Bir xil «To'g'ri!» tez
/// eskiradi va sezilmay qoladi; tasodifiy tanlov esa e'tiborni ushlaydi.
class Maqtov {
  Maqtov._();

  static const _oddiy = [
    "To'g'ri!",
    "Zo'r!",
    "Aynan!",
    "Barakalla!",
    "Ha, shunday!",
    "Ajoyib!",
    "Topdingiz!",
    "Yaxshi!",
  ];

  static const _kombo = [
    "Olov! Ketma-ket {n}",
    "{n} ta ketma-ket — davom!",
    "To'xtatib bo'lmaydi! {n}",
    "Qatorasiga {n}!",
  ];

  static const _katta = [
    "Afsona! {n} ta ketma-ket",
    "Bu darajaga kam odam chiqadi — {n}!",
    "Mukammal seriya: {n}",
  ];

  static const _bonus = [
    "Omadli javob! Bonus",
    "Sovg'a javob! Bonus",
    "Bugun sizning kuningiz! Bonus",
  ];

  static const _xato = [
    "Deyarli! Bu so'z yana keladi",
    "Hechqisi yo'q — eslab qoling",
    "Yaqin edi. Yana urinib ko'ramiz",
    "Bu xato — o'rganishning bir qismi",
  ];

  static String togri(Random rnd, {required int ketmaKet, bool bonus = false}) {
    if (bonus) return _bonus[rnd.nextInt(_bonus.length)];
    if (ketmaKet >= 10) {
      return _katta[rnd.nextInt(_katta.length)].replaceAll('{n}', '$ketmaKet');
    }
    if (ketmaKet >= 3) {
      return _kombo[rnd.nextInt(_kombo.length)].replaceAll('{n}', '$ketmaKet');
    }
    return _oddiy[rnd.nextInt(_oddiy.length)];
  }

  static String xato(Random rnd) => _xato[rnd.nextInt(_xato.length)];
}

/// Zarrachalar portlashi — to'g'ri javob bosilgan joydan otiladi.
///
/// [trigger] o'zgarganda bir marta otiladi. Zarrachalar kichik, tez va
/// tortishish bilan tushadi — «qo'lga tekkan» taassurot beradi.
class Portlash extends StatefulWidget {
  final Object? trigger;
  final Widget child;
  final List<Color> ranglar;

  const Portlash({
    super.key,
    required this.trigger,
    required this.child,
    this.ranglar = const [
      AppColors.gold,
      AppColors.emerald,
      AppColors.coral,
      AppColors.indigo,
      AppColors.goldLight,
    ],
  });

  @override
  State<Portlash> createState() => _PortlashState();
}

class _Zarra {
  final double burchak, tezlik, olcham;
  final Color rang;
  _Zarra(this.burchak, this.tezlik, this.olcham, this.rang);
}

class _PortlashState extends State<Portlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  final _rnd = Random();
  List<_Zarra> _zarralar = const [];

  @override
  void didUpdateWidget(Portlash old) {
    super.didUpdateWidget(old);
    if (widget.trigger != null && widget.trigger != old.trigger) {
      _zarralar = List.generate(
        18,
        (i) => _Zarra(
          -pi / 2 + (_rnd.nextDouble() - 0.5) * pi * 1.4,
          90 + _rnd.nextDouble() * 120,
          3 + _rnd.nextDouble() * 4,
          widget.ranglar[_rnd.nextInt(widget.ranglar.length)],
        ),
      );
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => _c.isAnimating
                  ? CustomPaint(painter: _PortlashPainter(_zarralar, _c.value))
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PortlashPainter extends CustomPainter {
  final List<_Zarra> zarralar;
  final double t;
  _PortlashPainter(this.zarralar, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final markaz = Offset(size.width / 2, size.height / 2);
    final e = Curves.easeOutCubic.transform(t);
    for (final z in zarralar) {
      final dx = cos(z.burchak) * z.tezlik * e;
      // Tortishish: yuqoriga otilib, keyin pastga tushadi.
      final dy = sin(z.burchak) * z.tezlik * e + 140 * t * t;
      final p = Paint()..color = z.rang.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.drawCircle(markaz + Offset(dx, dy), z.olcham * (1 - t * 0.5), p);
    }
  }

  @override
  bool shouldRepaint(_PortlashPainter old) => old.t != t;
}

/// Uchuvchi ball — «+2», «+5 bonus» yozuvi yuqoriga ko'tarilib so'nadi.
///
/// [trigger] o'zgarganda [matn] bilan bir marta uchadi.
class UchuvchiBall extends StatefulWidget {
  final Object? trigger;
  final String matn;
  final Color rang;

  const UchuvchiBall({
    super.key,
    required this.trigger,
    required this.matn,
    this.rang = AppColors.gold,
  });

  @override
  State<UchuvchiBall> createState() => _UchuvchiBallState();
}

class _UchuvchiBallState extends State<UchuvchiBall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  String _matn = '';

  @override
  void didUpdateWidget(UchuvchiBall old) {
    super.didUpdateWidget(old);
    if (widget.trigger != null && widget.trigger != old.trigger) {
      _matn = widget.matn;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          if (!_c.isAnimating) return const SizedBox.shrink();
          final t = kExpoOut.transform(_c.value);
          final fade = _c.value < 0.6 ? 1.0 : 1 - (_c.value - 0.6) / 0.4;
          final kattalik =
              1.0 +
              0.35 * Curves.elasticOut.transform(_c.value.clamp(0, 0.5) * 2);
          return Transform.translate(
            offset: Offset(0, -70 * t),
            child: Transform.scale(
              scale: kattalik,
              child: Opacity(
                opacity: fade.clamp(0, 1),
                child: Text(
                  _matn,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: widget.rang,
                    shadows: const [Shadow(color: Colors.white, blurRadius: 8)],
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

/// Kombo olovi — ketma-ket to'g'ri javoblar soni. 3 dan boshlab ko'rinadi,
/// 5 va 10 da rangi va kattaligi o'sadi: o'quvchi seriyani UZMASLIKKA
/// intiladi — bu eng kuchli «yana bitta» sababi.
class KomboOlov extends StatelessWidget {
  final int ketmaKet;
  const KomboOlov({super.key, required this.ketmaKet});

  @override
  Widget build(BuildContext context) {
    if (ketmaKet < 3) return const SizedBox(height: 26);
    final (rang, olcham) = ketmaKet >= 10
        ? (AppColors.indigo, 22.0)
        : ketmaKet >= 5
        ? (AppColors.gold, 19.0)
        : (AppColors.coral, 16.0);
    return Pulse(
      trigger: ketmaKet,
      peak: 1.35,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: rang.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: olcham,
              color: rang,
            ),
            const SizedBox(width: 2),
            Text(
              '$ketmaKet',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: rang,
                fontSize: olcham - 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmentli progress — raunddagi har savol bitta katak. Katak to'lganda
/// «pop» beradi. Uzluksiz chiziqdan farqi: o'quvchi «yana nechta qoldi»
/// ni sanamasdan ko'radi — marra aniq.
class SegmentliBar extends StatelessWidget {
  final int jami;
  final int tolgan;
  final Color? rang;
  final Color? fon;

  const SegmentliBar({
    super.key,
    required this.jami,
    required this.tolgan,
    this.rang,
    this.fon,
  });

  @override
  Widget build(BuildContext context) {
    final rang = this.rang ?? AppColors.emerald;
    final fon = this.fon ?? AppColors.softGreen;
    return Row(
      children: [
        for (var i = 0; i < jami; i++) ...[
          Expanded(
            child: Pulse(
              trigger: i < tolgan ? 1 : 0,
              peak: 1.25,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: kExpoOut,
                height: 9,
                decoration: BoxDecoration(
                  color: i < tolgan ? rang : fon,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: i < tolgan
                      ? [
                          BoxShadow(
                            color: rang.withValues(alpha: 0.35),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          if (i < jami - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

/// Uchta yulduz — birin-ketin sakrab chiqadi. Olinmagani xira qoladi:
/// «keyingi safar to'ldiraman» degan istak shu bo'shliqdan tug'iladi.
class Yulduzlar extends StatelessWidget {
  final int soni;
  final double olcham;
  const Yulduzlar({super.key, required this.soni, this.olcham = 44});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Reveal(
            delay: Duration(milliseconds: 250 + i * 220),
            fromScale: 0.2,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: i == 1 ? 10 : 0,
                left: 3,
                right: 3,
              ),
              child: Icon(
                Icons.star_rounded,
                size: i == 1 ? olcham * 1.25 : olcham,
                color: i < soni
                    ? AppColors.gold
                    : Colors.black.withValues(alpha: 0.12),
                shadows: i < soni
                    ? [
                        Shadow(
                          color: AppColors.gold.withValues(alpha: 0.6),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Raund bekati — 8 savoldan keyin to'xtash joyi.
///
/// Bu yerda o'quvchi nafas rostlaydi, natijasini ko'radi va O'ZI
/// «davom etaman» deydi. Ixtiyoriy davom majburiy davomdan ko'ra ko'proq
/// vaqt beradi: odam o'zi tanlagan ishni tashlamaydi.
class RaundBekati extends StatelessWidget {
  final int raund;
  final int yulduz;
  final int togri;
  final int jami;
  final int ball;
  final int engUzunKombo;
  final String keyingiNomi;
  final VoidCallback onDavom;
  final VoidCallback onYetadi;

  /// Mukammal raundda yulduzlar ostida ko'rsatiladigan sovg'a (ixtiyoriy).
  final Widget? sandiq;

  const RaundBekati({
    super.key,
    required this.raund,
    required this.yulduz,
    required this.togri,
    required this.jami,
    required this.ball,
    required this.engUzunKombo,
    required this.keyingiNomi,
    required this.onDavom,
    required this.onYetadi,
    this.sandiq,
  });

  @override
  Widget build(BuildContext context) {
    final sarlavha = switch (yulduz) {
      3 => 'Mukammal raund!',
      2 => 'Juda yaxshi!',
      _ => 'Raund tugadi',
    };
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
          child: Column(
            children: [
              Yulduzlar(soni: yulduz),
              if (sandiq != null) ...[
                const SizedBox(height: 10),
                Reveal(
                  delay: const Duration(milliseconds: 1000),
                  fromScale: 0.6,
                  child: sandiq!,
                ),
              ],
              const SizedBox(height: 14),
              Reveal(
                delay: const Duration(milliseconds: 900),
                child: Text(
                  sarlavha,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Reveal(
                delay: const Duration(milliseconds: 980),
                child: Text(
                  '$raund-raund · $togri / $jami to\'g\'ri',
                  style: TextStyle(color: AppColors.matn2, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
              Reveal(
                delay: const Duration(milliseconds: 1060),
                child: Row(
                  children: [
                    Expanded(
                      child: _Korsatkich(
                        ikon: Icons.star_rounded,
                        rang: AppColors.gold,
                        qiymat: ball,
                        nom: 'ball',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Korsatkich(
                        ikon: Icons.local_fire_department_rounded,
                        rang: AppColors.coral,
                        qiymat: engUzunKombo,
                        nom: 'eng uzun seriya',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Reveal(
                delay: const Duration(milliseconds: 1160),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Tactile(
                        child: FilledButton.icon(
                          onPressed: onDavom,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(
                            'Davom etish — $keyingiNomi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onYetadi,
                      child: Text(
                        'Bugunga yetadi',
                        style: TextStyle(
                          color: AppColors.matn3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (yulduz == 3) const Positioned.fill(child: Confetti()),
      ],
    );
  }
}

class _Korsatkich extends StatelessWidget {
  final IconData ikon;
  final Color rang;
  final int qiymat;
  final String nom;
  const _Korsatkich({
    required this.ikon,
    required this.rang,
    required this.qiymat,
    required this.nom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: rang.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(ikon, color: rang, size: 26),
          const SizedBox(height: 4),
          CountUp(
            value: qiymat,
            duration: const Duration(milliseconds: 700),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: rang,
            ),
          ),
          Text(nom, style: TextStyle(fontSize: 12, color: AppColors.matn2)),
        ],
      ),
    );
  }
}

/// Daraja oshganda tepadan tushadigan banner («Kumush darajasi!»).
class DarajaBanner extends StatelessWidget {
  final String nom;
  final int daraja;
  const DarajaBanner({super.key, required this.nom, required this.daraja});

  @override
  Widget build(BuildContext context) => MukofotBanner(
    ikon: Icons.workspace_premium_rounded,
    matn: "Yangi daraja: $nom ($daraja-pog'ona)!",
  );
}

/// Kunlik maqsad bajarilganda chiqadigan banner.
class MaqsadBanner extends StatelessWidget {
  final int ball;
  const MaqsadBanner({super.key, required this.ball});

  @override
  Widget build(BuildContext context) => MukofotBanner(
    ikon: Icons.emoji_events_rounded,
    matn: 'Kunlik maqsad bajarildi! +$ball ball',
  );
}

/// Oltin banner — bir martalik katta mukofotlar uchun.
class MukofotBanner extends StatelessWidget {
  final IconData ikon;
  final String matn;
  const MukofotBanner({super.key, required this.ikon, required this.matn});

  @override
  Widget build(BuildContext context) {
    return Reveal(
      fromScale: 0.7,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gold, AppColors.goldLight],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(ikon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                matn,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Qiyin so'z» o'rgatish kartasi — so'rashdan OLDIN ko'rsatiladi.
///
/// Uch marta xato qilingan so'zni to'rtinchi marta shunchaki so'rash
/// foydasiz: o'quvchi uni bilmaydi. Avval ko'rsatamiz, eshittiramiz,
/// keyin so'raymiz — shunda javob taxmin emas, eslash bo'ladi.
class QiyinKarta extends StatelessWidget {
  final String ar;
  final String uz;
  final int xatoSoni;
  final VoidCallback onOvoz;
  final VoidCallback onTayyor;

  const QiyinKarta({
    super.key,
    required this.ar,
    required this.uz,
    required this.xatoSoni,
    required this.onOvoz,
    required this.onTayyor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.psychology_rounded,
                size: 18,
                color: AppColors.coral,
              ),
              const SizedBox(width: 6),
              Text(
                'Qiyin so\'z — $xatoSoni marta adashilgan',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.coral,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Reveal(
            fromScale: 0.9,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
              decoration: BoxDecoration(
                color: AppColors.karta,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.coral.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.coral.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      ar,
                      textAlign: TextAlign.center,
                      style: AppTheme.arabic(
                        size: 44,
                        color: AppColors.emerald,
                        w: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const OrnamentDivider(),
                  const SizedBox(height: 12),
                  Text(
                    uz,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Tactile(
                    child: Material(
                      color: AppColors.emerald,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onOvoz,
                        child: const SizedBox(
                          width: 54,
                          height: 54,
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Bir daqiqa qarab turing, keyin so\'raymiz.',
            style: TextStyle(color: AppColors.matn3, fontSize: 13),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: Tactile(
              child: FilledButton(
                onPressed: onTayyor,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Eslab oldim',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
