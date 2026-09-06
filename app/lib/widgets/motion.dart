import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ilovaning harakat (motion) tizimi — GSAP uslubidagi effektlar, Flutter'da.
///
/// Nega alohida fayl: har ekran o'zicha animatsiya yozsa, ilova «har xil
/// qo'l bilan» chizilgandek tuyuladi. Bu yerdagi vidjetlar bitta ritm va
/// bitta egri chiziq (easeOutExpo) bilan ishlaydi — shunda hamma ekran
/// bir oilaga o'xshaydi.
///
/// GSAP nomlari bilan mos keladi, qidirish oson bo'lsin:
///   gsap.from(..., {stagger})   -> [Stagger]
///   gsap.from(..., {y, opacity}) -> [Reveal]
///   yoyo: true, repeat: -1      -> [Float]
///   shine / highlight sweep     -> [Shine]
///   countUp                     -> [CountUp]
///   scale pulse                 -> [Pulse]
///   x shake                     -> [Shake]
///   width tween                 -> [AnimatedBar]
///   press scale                 -> [Tactile]

/// Ilovaning asosiy egri chizig'i — GSAP'dagi «expo.out».
/// Tez boshlanib, oxirida nafis sekinlashadi: premium his shundan keladi.
const Curve kExpoOut = Curves.easeOutExpo;

/// Element paydo bo'lishi: shaffoflik + pastdan siljish + yengil kattalashish.
///
/// [delay] bilan ketma-ketlik yasaladi; ko'p element bo'lsa [Stagger]
/// qulayroq.
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final double fromScale;

  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.offsetY = 26,
    this.fromScale = 0.96,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.7, curve: Curves.easeOut),
  );
  late final Animation<double> _move = CurvedAnimation(
    parent: _c,
    curve: kExpoOut,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _move.value;
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - t)),
            child: Transform.scale(
              scale: widget.fromScale + (1 - widget.fromScale) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Bir nechta elementni ketma-ket jonlantiradi — GSAP'dagi `stagger`.
///
/// Har keyingi element [step] ga kechroq boshlanadi. 80 ms — ko'z
/// «to'lqin» sifatida sezadigan, lekin kutdirmaydigan oraliq.
class Stagger extends StatelessWidget {
  final List<Widget> children;
  final Duration start;
  final Duration step;
  final double offsetY;

  const Stagger({
    super.key,
    required this.children,
    this.start = Duration.zero,
    this.step = const Duration(milliseconds: 80),
    this.offsetY = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          Reveal(
            delay: start + step * i,
            offsetY: offsetY,
            child: children[i],
          ),
      ],
    );
  }
}

/// Yengil suzish — cheksiz yuqoriga-pastga (GSAP `yoyo` + `repeat: -1`).
/// Katta arabcha harf yoki ikonka «tirik» ko'rinishi uchun.
class Float extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration period;

  const Float({
    super.key,
    required this.child,
    this.amplitude = 6,
    this.period = const Duration(milliseconds: 3200),
  });

  @override
  State<Float> createState() => _FloatState();
}

class _FloatState extends State<Float> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          math.sin(_c.value * 2 * math.pi) * widget.amplitude,
        ),
        child: child,
      ),
    );
  }
}

/// Karta ustidan o'tadigan yaltiroq chiziq — «shine sweep».
///
/// Har [every] da bir marta o'tadi, qolgan vaqt ko'rinmaydi. Doim
/// yaltirab tursa arzon ko'rinadi; vaqti-vaqti bilan bo'lsa — qimmat.
class Shine extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Duration every;
  final double opacity;

  const Shine({
    super.key,
    required this.child,
    required this.borderRadius,
    this.every = const Duration(milliseconds: 4200),
    this.opacity = 0.22,
  });

  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.every,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  // Sweep faqat davrning birinchi 35% ida o'tadi.
                  final p = (_c.value / 0.35).clamp(0.0, 1.0);
                  if (p >= 1) return const SizedBox.shrink();
                  final x = -1.6 + p * 3.2;
                  return FractionalTranslation(
                    translation: Offset(x, 0),
                    child: Transform.rotate(
                      angle: -0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: widget.opacity),
                              Colors.white.withValues(alpha: 0),
                            ],
                            stops: const [0.35, 0.5, 0.65],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Raqamning «yugurib» o'sishi — XP yoki foiz uchun.
class CountUp extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String suffix;
  final Duration duration;

  const CountUp({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1100),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: kExpoOut,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Taraqqiyot chizig'i — qiymat o'zgarganda silliq to'ladi.
class AnimatedBar extends StatelessWidget {
  final double value;
  final double height;
  final Color color;
  final Color background;
  final Duration duration;

  const AnimatedBar({
    super.key,
    required this.value,
    this.height = 10,
    required this.color,
    required this.background,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: background),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: duration,
              curve: kExpoOut,
              builder: (context, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.55),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir martalik «puls» — to'g'ri javobda. [trigger] o'zgarganda qayta o'ynaydi.
class Pulse extends StatefulWidget {
  final Widget child;
  final Object? trigger;
  final double peak;

  const Pulse({super.key, required this.child, this.trigger, this.peak = 1.06});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _s = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: widget.peak), weight: 35),
    TweenSequenceItem(tween: Tween(begin: widget.peak, end: 1), weight: 65),
  ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));

  @override
  void didUpdateWidget(covariant Pulse old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.trigger != null) {
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
    return ScaleTransition(scale: _s, child: widget.child);
  }
}

/// Bir martalik silkinish — xato javobda. [trigger] o'zgarganda o'ynaydi.
class Shake extends StatefulWidget {
  final Widget child;
  final Object? trigger;
  final double amplitude;

  const Shake({
    super.key,
    required this.child,
    this.trigger,
    this.amplitude = 8,
  });

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void didUpdateWidget(covariant Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.trigger != null) {
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
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        // So'nuvchi sinus: boshida kuchli, oxirida tinchiydi.
        final x = math.sin(t * math.pi * 4) * widget.amplitude * (1 - t);
        return Transform.translate(offset: Offset(x, 0), child: child);
      },
    );
  }
}

/// Bosilganda kichrayish + soyaning yig'ilishi — «tactile» his.
/// Ichki InkWell'ni to'smaydi.
class Tactile extends StatefulWidget {
  final Widget child;
  final double scale;

  const Tactile({super.key, required this.child, this.scale = 0.965});

  @override
  State<Tactile> createState() => _TactileState();
}

class _TactileState extends State<Tactile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Fon uchun sekin suzuvchi yumshoq rangli dog'lar — «aurora».
///
/// Blur ishlatilmaydi (web'da qimmat); dog' radial gradient bilan
/// chiziladi, chekkasi o'zi yumshoq. Ekran «tirik» va chuqur tuyuladi.
class Aurora extends StatefulWidget {
  final List<Color> colors;
  const Aurora({super.key, required this.colors});

  @override
  State<Aurora> createState() => _AuroraState();
}

class _AuroraState extends State<Aurora> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

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
          painter: _AuroraPainter(_c.value, widget.colors),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  _AuroraPainter(this.t, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < colors.length; i++) {
      final phase = t * 2 * math.pi + i * 2.1;
      final cx = size.width * (0.2 + 0.6 * (0.5 + 0.5 * math.sin(phase)));
      final cy = size.height * (0.1 + 0.5 * (0.5 + 0.5 * math.cos(phase * 0.8)));
      final r = size.shortestSide * (0.45 + 0.1 * i);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[i].withValues(alpha: 0.16),
            colors[i].withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}
