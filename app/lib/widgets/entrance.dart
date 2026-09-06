import 'package:flutter/material.dart';

import 'motion.dart';

/// Eski nomlar — endi yangi harakat tizimiga ([motion.dart]) yo'naltiradi.
///
/// Nega o'chirilmadi: `EntranceFade` va `PressableScale` o'nlab ekranda
/// ishlatiladi. Ularni bu yerda [Reveal] va [Tactile] ga ulash bilan
/// HAMMA ekran bir zumda yangi easing (expo.out), kattalashib chiqish va
/// bosish hissini oladi — birorta ekranga tegmasdan.
class PressableScale extends StatelessWidget {
  final Widget child;
  final double scale;
  const PressableScale({super.key, required this.child, this.scale = 0.965});

  @override
  Widget build(BuildContext context) => Tactile(scale: scale, child: child);
}

class EntranceFade extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const EntranceFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.offsetY = 22,
  });

  @override
  Widget build(BuildContext context) => Reveal(
    delay: delay,
    duration: duration,
    offsetY: offsetY,
    child: child,
  );
}
