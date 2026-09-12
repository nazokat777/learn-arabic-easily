import 'package:flutter/material.dart' hide Text;

import '../main.dart';
import '../mashq/mukofot.dart' show BugunChizigi;
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import '../widgets/uz_text.dart';
import 'lesson/gap_tuzish.dart';
import 'tarjima_mashqi.dart';

/// Mashqlar bo'limidagi «Gap tuzish» — o'tilgan Qiroat darslarining kitob
/// mashqlaridan 12 ta gap (juftlar mos kelgan darslardan). Hali dars
/// tugatilmagan bo'lsa — 1-kitobning boshidan.
void gapTuzishniOch(BuildContext context) {
  var juftlar = <(String, String)>[];
  for (final l in repo.qiroatLessons) {
    if (!progress.isCompleted(l.completionId)) continue;
    juftlar.addAll(_juftlar(l));
  }
  if (juftlar.length < 5) {
    juftlar = [for (final l in repo.qiroatLessons.take(3)) ..._juftlar(l)];
  }
  if (juftlar.isEmpty) return;
  juftlar.shuffle();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GapTuzishEkrani(juftlar: juftlar.take(12).toList()),
    ),
  );
}

List<(String, String)> _juftlar(dynamic l) {
  final (_, uz, ar) = TarjimaMashqi.ajrat(l);
  if (ar == null) return const [];
  return [for (var i = 0; i < uz.length; i++) (uz[i], ar[i])];
}

class GapTuzishEkrani extends StatefulWidget {
  final List<(String, String)> juftlar;
  const GapTuzishEkrani({super.key, required this.juftlar});

  @override
  State<GapTuzishEkrani> createState() => _GapTuzishEkraniState();
}

class _GapTuzishEkraniState extends State<GapTuzishEkrani> {
  int _ball = 0;
  bool _tugadi = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gap tuzish')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _tugadi
              ? _yakun()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: AppColors.karta,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.indigo.withValues(alpha: 0.35),
                        ),
                      ),
                      child: GapTuzish(
                        juftlar: widget.juftlar,
                        award: (b) {
                          _ball += b;
                          progress.addXp(b);
                        },
                        onDone: () => setState(() => _tugadi = true),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _yakun() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
    child: Column(
      children: [
        Reveal(
          fromScale: 0.6,
          child: GlowRing(
            size: 128,
            color: AppColors.indigo,
            child: const Float(
              amplitude: 4,
              child: Icon(
                Icons.extension_rounded,
                size: 60,
                color: AppColors.indigo,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Gaplar tuzildi!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.juftlar.length} ta gap  ·  +$_ball ball',
          style: TextStyle(color: AppColors.matn2, fontSize: 14),
        ),
        const SizedBox(height: 18),
        const BugunChizigi(),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Tayyor',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    ),
  );
}
