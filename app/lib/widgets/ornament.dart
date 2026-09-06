import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Islomiy bezaklar — ilovaning o'ziga xos vizual imzosi.
///
/// Nega kerak: yashil+oltin rang va Amiri shrifti «arabcha» his beradi,
/// lekin premium islomiy ilovani boshqalardan ajratib turadigan narsa —
/// GEOMETRIK NAQSH. Masjid koshinlaridagi 8 uchli yulduz (xatam) tilini
/// ko'rgan odam darrov «bu jiddiy, did bilan qilingan» deb his qiladi.
///
/// Naqsh doim juda xira chiziladi (alpha ~0.06–0.10): u fon, mazmun
/// emas. Ko'zga tashlanib ketsa arzon ko'rinadi.

/// 8 uchli yulduz (xatam) tiling — CustomPainter bilan chiziladi,
/// rasm fayli kerak emas, har o'lchamda tiniq.
class GirihPattern extends StatelessWidget {
  final Color color;
  final double opacity;
  final double cell;
  final double strokeWidth;

  const GirihPattern({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.08,
    this.cell = 56,
    this.strokeWidth = 1.1,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GirihPainter(
          color: color.withValues(alpha: opacity),
          cell: cell,
          strokeWidth: strokeWidth,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _GirihPainter extends CustomPainter {
  final Color color;
  final double cell;
  final double strokeWidth;
  _GirihPainter({
    required this.color,
    required this.cell,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    // Har katakda: ikkita kvadrat (biri 45° burilgan) = 8 uchli yulduz.
    // Qo'shni yulduzlar orasidagi bo'shliq o'zi to'rt burchakli
    // «ko'prik» hosil qiladi — klassik xatam tilining o'zi.
    final half = cell * 0.36;
    for (var y = -cell; y < size.height + cell; y += cell) {
      for (var x = -cell; x < size.width + cell; x += cell) {
        final c = Offset(x + cell / 2, y + cell / 2);
        _square(canvas, p, c, half, 0);
        _square(canvas, p, c, half, math.pi / 4);
      }
    }
  }

  void _square(Canvas canvas, Paint p, Offset c, double half, double angle) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = angle + i * math.pi / 2 + math.pi / 4;
      final r = half * math.sqrt2;
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_GirihPainter old) =>
      old.color != color || old.cell != cell || old.strokeWidth != strokeWidth;
}

/// Konfetti otilishi — dars tugaganda.
///
/// Zarrachalar markazdan yuqoriga otilib, tortishish bilan tushadi va
/// aylanadi. Ranglar ilovaniki: oltin, zumrad, marjon, krem — «bayram»
/// his beradi, lekin begona ko'rinmaydi. Bir marta o'ynaydi.
class Confetti extends StatefulWidget {
  final int count;
  final Duration duration;
  const Confetti({
    super.key,
    this.count = 90,
    this.duration = const Duration(milliseconds: 2600),
  });

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Zarra {
  final double x0, y0, vx, vy, spin, size, phase;
  final Color color;
  final bool round;
  _Zarra({
    required this.x0,
    required this.y0,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.size,
    required this.phase,
    required this.color,
    required this.round,
  });
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late final List<_Zarra> _zarralar = _yasa();

  List<_Zarra> _yasa() {
    final rnd = math.Random();
    const ranglar = [
      AppColors.gold,
      AppColors.goldLight,
      AppColors.emerald,
      AppColors.coral,
      AppColors.teal,
      Color(0xFFFFF4D6),
    ];
    return List.generate(widget.count, (i) {
      // Yuqoriga va yon tomonlarga otiladi (burchak −150°…−30°).
      final ang = -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 0.9;
      final speed = 0.55 + rnd.nextDouble() * 0.75;
      return _Zarra(
        x0: 0.5 + (rnd.nextDouble() - 0.5) * 0.2,
        y0: 0.42,
        vx: math.cos(ang) * speed,
        vy: math.sin(ang) * speed,
        spin: (rnd.nextDouble() - 0.5) * 14,
        size: 5 + rnd.nextDouble() * 6,
        phase: rnd.nextDouble(),
        color: ranglar[rnd.nextInt(ranglar.length)],
        round: rnd.nextBool(),
      );
    });
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
          painter: _ConfettiPainter(_c.value, _zarralar),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<_Zarra> zarralar;
  _ConfettiPainter(this.t, this.zarralar);

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final g = 1.15; // tortishish
    final fade = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
    for (final z in zarralar) {
      final x = (z.x0 + z.vx * t * 0.9) * size.width;
      final y = (z.y0 + z.vy * t + 0.5 * g * t * t) * size.height;
      if (y > size.height + 20) continue;
      final paint = Paint()..color = z.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(z.spin * t + z.phase * math.pi);
      if (z.round) {
        canvas.drawCircle(Offset.zero, z.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: z.size,
              height: z.size * 0.6,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Bezakli ajratgich — chiziq o'rtasida kichik yulduz. Bo'lim sarlavhalari
/// ostida ishlatiladi; oddiy Divider o'rniga did beradi.
class OrnamentDivider extends StatelessWidget {
  final Color color;
  const OrnamentDivider({super.key, this.color = AppColors.gold});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: 0.55),
            ],
          ),
        ),
      ),
    );
    final lineR = Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.55),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
        lineR,
      ],
    );
  }
}

/// Yaltiroq nur halqasi — kubok/medal atrofida sekin aylanadi.
class GlowRing extends StatefulWidget {
  final double size;
  final Color color;
  final Widget child;
  const GlowRing({
    super.key,
    required this.size,
    required this.child,
    this.color = AppColors.gold,
  });

  @override
  State<GlowRing> createState() => _GlowRingState();
}

class _GlowRingState extends State<GlowRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Transform.rotate(
              angle: _c.value * 2 * math.pi,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      widget.color.withValues(alpha: 0),
                      widget.color.withValues(alpha: 0.55),
                      widget.color.withValues(alpha: 0),
                      widget.color.withValues(alpha: 0.35),
                      widget.color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: widget.size * 0.86,
            height: widget.size * 0.86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.35),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
