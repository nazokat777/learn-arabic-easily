import 'package:flutter/material.dart' hide Text;

import '../main.dart';
import '../mashq/tovush.dart';
import '../nishonlar.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import '../widgets/uz_text.dart';

/// Nishonlar to'plami — ochilganlari rangli (sanasi bilan), qolganlari
/// kulrang lekin KO'RINADI: «keyingisi nima» savoli o'z-o'zidan tug'iladi
/// (to'plamni to'ldirish istagi). Hech narsa yashirilmaydi — maqsad aniq.
class NishonlarEkrani extends StatelessWidget {
  const NishonlarEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nishonlar')),
      body: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final olingan = progress.nishonSoni;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text(
                    '$olingan / ${nishonlar.length} ochildi',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBar(
                value: olingan / nishonlar.length,
                height: 10,
                color: AppColors.gold,
                background: AppColors.softGreen,
              ),
              const SizedBox(height: 16),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170,
                  mainAxisExtent: 150,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                children: [
                  for (final (i, n) in nishonlar.indexed)
                    Reveal(
                      delay: Duration(milliseconds: 30 * i),
                      child: NishonKatagi(nishon: n),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bitta nishon katagi: ochiq — rangli va sanali; yopiq — kulrang, qulf.
class NishonKatagi extends StatelessWidget {
  final Nishon nishon;
  const NishonKatagi({super.key, required this.nishon});

  @override
  Widget build(BuildContext context) {
    final ochiq = progress.nishonOlinganmi(nishon.id);
    final sana = progress.nishonSanasi(nishon.id);
    final rang = ochiq ? nishon.rang : AppColors.matn3;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: ochiq ? rang.withValues(alpha: 0.10) : AppColors.karta,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ochiq ? rang.withValues(alpha: 0.5) : AppColors.chiziq2,
          width: ochiq ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rang.withValues(alpha: ochiq ? 0.18 : 0.10),
              boxShadow: ochiq
                  ? [
                      BoxShadow(
                        color: rang.withValues(alpha: 0.35),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              ochiq ? nishon.ikon : Icons.lock_outline_rounded,
              color: rang,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nishon.nom,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
              color: ochiq ? AppColors.ink : AppColors.matn2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ochiq && sana != null ? sana : nishon.tavsif,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.2,
              color: AppColors.matn3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Yangi nishon oynasi — konfetti, nishon va nomi. Bir nechta bo'lsa
/// ketma-ket ko'rsatiladi. Ochilish LAHZASI — mukofotning o'zi: o'quvchi
/// buni «yon panelda paydo bo'ldi» deb emas, marosim sifatida ko'rsin.
Future<void> nishonOynasi(BuildContext context, List<String> idlar) async {
  for (final id in idlar) {
    final n = nishonTop(id);
    if (n == null || !context.mounted) continue;
    Tovush.daraja();
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'nishon',
      barrierColor: AppColors.deep.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 420),
      transitionBuilder: (context, a, _, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
          child: child,
        ),
      ),
      pageBuilder: (context, _, _) => Stack(
        children: [
          const Positioned.fill(child: Confetti(count: 120)),
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(28),
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 22),
                constraints: const BoxConstraints(maxWidth: 360),
                decoration: BoxDecoration(
                  color: AppColors.karta,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlowRing(
                      size: 120,
                      color: n.rang,
                      child: Float(
                        amplitude: 4,
                        child: Icon(n.ikon, size: 58, color: n.rang),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Yangi nishon!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.matn2,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.nom,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.tavsif,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.matn2, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: n.rang,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Zo\'r!',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
