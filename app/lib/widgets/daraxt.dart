import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Bilim daraxti — o'quvchining butun yo'li bitta rasmda.
///
/// Tanasi va shoxlari daraja bilan o'sadi (ko'proq shox — chuqurroq
/// daraxt), har yodlangan so'z — bitta barg. Daraxt sekin tebranadi:
/// tirik narsa «meniki» degan his beradi, meniki bo'lgan narsani
/// qarovsiz qoldirish qiyin — bu ilovaga qaytishning eng sokin sababi.
///
/// Chizish arzon: shoxlar bir marta hisoblanadi (urug'li tasodif), faqat
/// tebranish burchagi kadr sayin o'zgaradi.
class BilimDaraxti extends StatefulWidget {
  /// Daraja (1..) — shoxlar chuqurligi.
  final int daraja;

  /// Yodlangan so'zlar — barglar soni.
  final int barglar;
  final double height;

  const BilimDaraxti({
    super.key,
    required this.daraja,
    required this.barglar,
    this.height = 150,
  });

  @override
  State<BilimDaraxti> createState() => _BilimDaraxtiState();
}

class _BilimDaraxtiState extends State<BilimDaraxti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _DaraxtPainter(
            daraja: widget.daraja,
            barglar: widget.barglar,
            t: _c.value,
          ),
        ),
      ),
    );
  }
}

class _Shox {
  final Offset a, b;
  final double qalinlik;
  final int chuqurlik;
  _Shox(this.a, this.b, this.qalinlik, this.chuqurlik);
}

class _DaraxtPainter extends CustomPainter {
  final int daraja;
  final int barglar;
  final double t;
  _DaraxtPainter({
    required this.daraja,
    required this.barglar,
    required this.t,
  });

  // Shoxlar (daraja, o'lcham) bo'yicha keshlanadi — kadr sayin emas.
  static final Map<String, List<_Shox>> _kesh = {};

  List<_Shox> _shoxlar(Size s) {
    final kalit = '$daraja-${s.width.round()}-${s.height.round()}';
    return _kesh.putIfAbsent(kalit, () {
      final rnd = Random(7 + daraja);
      final chuqurlik = (3 + daraja).clamp(3, 9);
      final natija = <_Shox>[];
      void osh(Offset a, double burchak, double uzunlik, double qalin, int d) {
        if (d == 0 || uzunlik < 4) return;
        final b = a + Offset(cos(burchak), sin(burchak)) * uzunlik;
        natija.add(_Shox(a, b, qalin, d));
        final n = d > chuqurlik - 2 ? 2 : (rnd.nextDouble() < 0.7 ? 2 : 3);
        for (var i = 0; i < n; i++) {
          final og = (rnd.nextDouble() - 0.5) * 1.1 + (i == 0 ? -0.35 : 0.35);
          osh(
            b,
            burchak + og,
            uzunlik * (0.66 + rnd.nextDouble() * 0.12),
            qalin * 0.68,
            d - 1,
          );
        }
      }

      osh(
        Offset(s.width / 2, s.height),
        -pi / 2,
        s.height * 0.3,
        s.height * 0.055,
        chuqurlik,
      );
      return natija;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shoxlar = _shoxlar(size);
    final tebranish = sin(t * 2 * pi) * 0.012;
    final tana = Paint()
      ..color = const Color(0xFF7A5A3A)
      ..strokeCap = StrokeCap.round;
    final tiplar = <Offset>[];
    for (final sh in shoxlar) {
      // Yuqori shoxlar ko'proq tebranadi — shamol tepada kuchli.
      final k = 1 - sh.chuqurlik / 10;
      final dx = (size.height - sh.b.dy) * tebranish * k;
      final a = Offset(sh.a.dx + dx * 0.6, sh.a.dy);
      final b = Offset(sh.b.dx + dx, sh.b.dy);
      canvas.drawLine(a, b, tana..strokeWidth = sh.qalinlik);
      if (sh.chuqurlik <= 3) tiplar.add(b);
    }
    // Barglar: uchlarga yaqin, urug'li tasodif — har safar bir joyda.
    if (tiplar.isEmpty || barglar <= 0) return;
    final rnd = Random(11);
    final soni = min(barglar, 320);
    for (var i = 0; i < soni; i++) {
      final tip = tiplar[i % tiplar.length];
      final og = Offset(
        (rnd.nextDouble() - 0.5) * 18,
        (rnd.nextDouble() - 0.5) * 14,
      );
      final rang = Color.lerp(
        AppColors.emerald,
        AppColors.success,
        rnd.nextDouble(),
      )!;
      canvas.drawCircle(
        tip + og,
        2.4 + rnd.nextDouble() * 1.6,
        Paint()..color = rang.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_DaraxtPainter old) =>
      old.t != t || old.daraja != daraja || old.barglar != barglar;
}
