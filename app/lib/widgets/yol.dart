import 'package:flutter/material.dart';

import '../theme.dart';
import 'motion.dart';

/// Yo'l bandi — dars ro'yxati oddiy ro'yxat emas, YO'L bo'lib ko'rinadi.
///
/// Chap tomonda tugunlar va ularni bog'lovchi chiziq: o'zlashtirilgan dars
/// to'la doira va belgi, hozirgi (navbatdagi) dars nur bilan puls,
/// keyingilari xira halqa. O'quvchi qayerda ekanini va oldinda qancha
/// borligini bir qarashda ko'radi — sanab o'tirmaydi.
class YolBand extends StatelessWidget {
  final bool birinchi;
  final bool oxirgi;
  final bool bajarildi;
  final bool joriy;
  final Color rang;
  final Widget child;

  const YolBand({
    super.key,
    required this.child,
    required this.rang,
    this.birinchi = false,
    this.oxirgi = false,
    this.bajarildi = false,
    this.joriy = false,
  });

  @override
  Widget build(BuildContext context) {
    final chiziq = rang.withValues(alpha: 0.22);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 3,
                    color: birinchi
                        ? Colors.transparent
                        : (bajarildi ? rang : chiziq),
                  ),
                ),
                _tugun(),
                Expanded(
                  child: Container(
                    width: 3,
                    color: oxirgi
                        ? Colors.transparent
                        : (bajarildi ? rang : chiziq),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _tugun() {
    if (bajarildi) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: rang,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: rang.withValues(alpha: 0.4), blurRadius: 8),
          ],
        ),
        child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
      );
    }
    if (joriy) {
      return GlowDot(rang: rang);
    }
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cream,
        border: Border.all(color: rang.withValues(alpha: 0.35), width: 2),
      ),
    );
  }
}

/// Hozirgi dars tuguni — nafas oluvchi nur halqasi.
class GlowDot extends StatefulWidget {
  final Color rang;
  const GlowDot({super.key, required this.rang});

  @override
  State<GlowDot> createState() => _GlowDotState();
}

class _GlowDotState extends State<GlowDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
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
      builder: (context, _) {
        final t = kExpoOut.transform(_c.value);
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: widget.rang, width: 3),
            boxShadow: [
              BoxShadow(
                color: widget.rang.withValues(alpha: 0.25 + 0.35 * t),
                blurRadius: 6 + 10 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
