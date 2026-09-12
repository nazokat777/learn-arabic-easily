import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// «WOW» qatlam: suzuvchi harflar, taraqqiyot halqasi, ochilish sahnasi.
///
/// Dizayn tamoyili: harakat mazmunni bezamaydi, unga chuqurlik beradi.
/// Har harakat sekin (1.5–8 s), kichik amplitudali va bir-biriga bog'liq
/// emas — «tirik», lekin chalg'itmaydi.

/// Hero fonida sekin suzuvchi arab harflari — xira, katta, har xil
/// tezlikda. Ilova ochilganda «bu tirik joy» hissi shu yerdan boshlanadi.
class SuzuvchiHarflar extends StatefulWidget {
  final double opacity;
  const SuzuvchiHarflar({super.key, this.opacity = 0.10});

  @override
  State<SuzuvchiHarflar> createState() => _SuzuvchiHarflarState();
}

class _SuzuvchiHarflarState extends State<SuzuvchiHarflar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  static const _harflar = ['ع', 'ب', 'ن', 'ق', 'م', 'ل', 'ح', 'س', 'ك', 'ي'];
  late final List<_Harf> _zarralar;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat();
    final rnd = Random(3);
    _zarralar = [
      for (var i = 0; i < _harflar.length; i++)
        _Harf(
          _harflar[i],
          rnd.nextDouble(),
          rnd.nextDouble(),
          0.5 + rnd.nextDouble(),
          22 + rnd.nextDouble() * 26,
        ),
    ];
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
        builder: (context, _) => CustomPaint(
          painter: _HarflarPainter(_zarralar, _c.value, widget.opacity),
        ),
      ),
    );
  }
}

class _Harf {
  final String h;
  final double x, y, tezlik, olcham;
  _Harf(this.h, this.x, this.y, this.tezlik, this.olcham);
}

class _HarflarPainter extends CustomPainter {
  final List<_Harf> z;
  final double t;
  final double opacity;
  _HarflarPainter(this.z, this.t, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    for (final h in z) {
      // Yuqoriga suzadi, chetdan chiqsa pastdan qaytadi; yon tomonga
      // sekin tebranadi.
      final y = ((h.y - t * h.tezlik) % 1.0) * (size.height + 60) - 30;
      final x = h.x * size.width + sin((t * 2 * pi + h.x * 6) * h.tezlik) * 10;
      final tp = TextPainter(
        text: TextSpan(
          text: h.h,
          style: AppTheme.arabic(
            size: h.olcham,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(_HarflarPainter old) => old.t != t;
}

/// Taraqqiyot halqasi — modul kartasida «nechta dars o'zlashtirildi».
/// Halqa ochilganda 0 dan qiymatgacha to'ladi.
class TaraqqiyotHalqasi extends StatelessWidget {
  final double foiz; // 0..1
  final Color rang;
  final double size;

  /// Berilsa foiz matni o'rniga chiziladi (masalan, kun ichidagi raqam).
  final Widget? child;
  const TaraqqiyotHalqasi({
    super.key,
    required this.foiz,
    required this.rang,
    this.size = 40,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: foiz.clamp(0, 1)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _HalqaPainter(v, rang),
          child: Center(
            child:
                child ??
                Text(
                  '${(v * 100).round()}%',
                  style: TextStyle(
                    fontSize: size * 0.26,
                    fontWeight: FontWeight.w900,
                    color: rang,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _HalqaPainter extends CustomPainter {
  final double v;
  final Color rang;
  _HalqaPainter(this.v, this.rang);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final markaz = Offset(r, r);
    final qalin = size.width * 0.11;
    canvas.drawCircle(
      markaz,
      r - qalin / 2,
      Paint()
        ..color = rang.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = qalin,
    );
    if (v <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: markaz, radius: r - qalin / 2),
      -pi / 2,
      2 * pi * v,
      false,
      Paint()
        ..color = rang
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = qalin,
    );
  }

  @override
  bool shouldRepaint(_HalqaPainter old) => old.v != v || old.rang != rang;
}

/// Ochilish sahnasi — ilova ishga tushganda bir marta: to'q yashil fon,
/// oltin halqa o'zini chizadi, harf o'sib chiqadi, nom paydo bo'ladi,
/// keyin hammasi erib bosh ekranga o'tadi. 1.6 soniya — kutish emas,
/// «pardaning ochilishi».
class OchilishSahnasi extends StatefulWidget {
  final Widget child;
  const OchilishSahnasi({super.key, required this.child});

  static bool _korsatildi = false;

  @override
  State<OchilishSahnasi> createState() => _OchilishSahnasiState();
}

class _OchilishSahnasiState extends State<OchilishSahnasi>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final bool _kerak;

  @override
  void initState() {
    super.initState();
    _kerak = !OchilishSahnasi._korsatildi;
    OchilishSahnasi._korsatildi = true;
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    if (_kerak) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_kerak) return widget.child;
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            if (t >= 1) return const SizedBox.shrink();
            // 0–0.55: halqa chiziladi va harf o'sadi; 0.45–0.7: nom;
            // 0.78–1: parda eriydi.
            final halqa = Curves.easeInOutCubic.transform(
              (t / 0.55).clamp(0, 1),
            );
            final harf = Curves.easeOutBack.transform(
              ((t - 0.15) / 0.4).clamp(0, 1),
            );
            final nom = ((t - 0.45) / 0.25).clamp(0.0, 1.0);
            final erish = 1 - ((t - 0.78) / 0.22).clamp(0.0, 1.0);
            return IgnorePointer(
              child: Opacity(
                opacity: erish,
                // Material — matn ostidagi sariq «xato» chizig'i chiqmasin
                // (Scaffold'dan tashqaridagi Text uchun kerak).
                child: Material(
                  color: AppColors.deep,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 132,
                          height: 132,
                          child: CustomPaint(
                            painter: _OltinHalqa(halqa),
                            child: Center(
                              child: Transform.scale(
                                scale: harf,
                                child: Text(
                                  'ع',
                                  style: AppTheme.arabic(
                                    size: 64,
                                    color: AppColors.goldLight,
                                    w: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Opacity(
                          opacity: nom,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - nom)),
                            child: const Text(
                              "Arab tilini oson o'rganamiz",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OltinHalqa extends CustomPainter {
  final double v;
  _OltinHalqa(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final markaz = Offset(r, r);
    canvas.drawArc(
      Rect.fromCircle(center: markaz, radius: r - 4),
      -pi / 2,
      2 * pi * v,
      false,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4,
    );
    if (v > 0.3) {
      canvas.drawCircle(
        markaz,
        r - 14,
        Paint()..color = AppColors.gold.withValues(alpha: 0.10 * (v - 0.3)),
      );
    }
  }

  @override
  bool shouldRepaint(_OltinHalqa old) => old.v != v;
}
