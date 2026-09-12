import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Tirik olov — seriya belgisi. Statik ikonka o'rniga lovullaydi.
///
/// Uch qatlam: tashqi marjon, o'rta amber, ichki oltin-oq. Har qatlam
/// o'z tezligida tebranadi, uchi shamolda egiladi. Olov «tirik» bo'lsa,
/// uni o'chirmaslik istagi kuchliroq — bu seriyaning butun mazmuni.
class Olov extends StatefulWidget {
  final double size;

  /// O'chiq holat: bugun hali yoqilmagan — xira, tebranmaydi.
  final bool xira;
  const Olov({super.key, this.size = 22, this.xira = false});

  @override
  State<Olov> createState() => _OlovState();
}

class _OlovState extends State<Olov> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.xira) {
      return Icon(
        Icons.local_fire_department_rounded,
        size: widget.size,
        color: Colors.white.withValues(alpha: 0.55),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size * 1.15),
        painter: _OlovPainter(_c.value),
      ),
    );
  }
}

class _OlovPainter extends CustomPainter {
  final double t;
  _OlovPainter(this.t);

  Path _alanga(Size s, double kenglik, double balandlik, double egilish) {
    final w = s.width, h = s.height;
    final cx = w / 2;
    final tepa = Offset(cx + egilish * w * 0.12, h * (1 - balandlik));
    final p = Path()..moveTo(cx, h);
    p.cubicTo(
      cx - w * kenglik,
      h * 0.95,
      cx - w * kenglik * 0.9,
      h * 0.45,
      tepa.dx,
      tepa.dy,
    );
    p.cubicTo(
      cx + w * kenglik * 0.9,
      h * 0.45,
      cx + w * kenglik,
      h * 0.95,
      cx,
      h,
    );
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = 2 * pi * t;
    // Uchta qatlam, har biri boshqa fazada lovullaydi.
    final tashqi = _alanga(
      size,
      0.48,
      0.92 + 0.06 * sin(a),
      0.5 * sin(a * 1.3),
    );
    final orta = _alanga(
      size,
      0.34,
      0.72 + 0.08 * sin(a * 1.7 + 1),
      0.6 * sin(a * 2.1 + 0.5),
    );
    final ichki = _alanga(
      size,
      0.2,
      0.48 + 0.08 * sin(a * 2.3 + 2),
      0.7 * sin(a * 2.9 + 1),
    );
    canvas.drawPath(tashqi, Paint()..color = AppColors.coral);
    canvas.drawPath(orta, Paint()..color = AppColors.amber);
    canvas.drawPath(ichki, Paint()..color = AppColors.goldLight);
  }

  @override
  bool shouldRepaint(_OlovPainter old) => old.t != t;
}
