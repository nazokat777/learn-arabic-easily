import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';

import '../content.dart';
import '../main.dart';
import '../mashq/bank.dart';
import '../mashq/mashq_ekran.dart';
import '../theme.dart';
import '../widgets/aralash_matn.dart';
import '../widgets/mastery_badge.dart';
import '../widgets/motion.dart';
import '../widgets/premium_tile.dart';
import '../widgets/speak_button.dart';

/// Sarf moduli — «Mukammal sarf darsligi» (Do'stmuhammad Nasriddin
/// Bodariy, Toshkent, 2009).
///
/// Nahv modulidan alohida ekran: o'sha kitobda har blok arabcha jumla va
/// uning tarjimasi edi, bu kitobda esa matn o'zbekcha yozilgan, arabcha
/// misollar gap ichida keladi (qarang: [AralashMatn]).
class SarfHome extends StatelessWidget {
  const SarfHome({super.key});

  @override
  Widget build(BuildContext context) {
    final darslar = repo.sarfLessons;
    return Scaffold(
      appBar: AppBar(title: const Text('Sarf')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: darslar.isEmpty
              ? const _BoshHolat()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    const Reveal(child: _Sarlavha()),
                    const SizedBox(height: 14),
                    for (var i = 0; i < darslar.length; i++)
                      Reveal(
                        delay: Duration(milliseconds: 40 * i),
                        child: _tile(context, darslar[i]),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, SarfLesson l) => PremiumTile(
    label: '${l.num}',
    title: l.title,
    arabicSubtitle: l.titleAr,
    accent: AppColors.indigo,
    trailing: MasteryBadge(lessonId: l.completionId),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SarfLessonScreen(lesson: l)),
    ),
  );
}

class _Sarlavha extends StatelessWidget {
  const _Sarlavha();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'دروس الصرف الكامل',
              style: AppTheme.arabic(size: 26, color: AppColors.indigo),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mukammal sarf darsligi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 2),
          const Text(
            "Do'stmuhammad Nasriddin Bodariy — Toshkent, «Movarounnahr», 2009",
            style: TextStyle(color: Colors.black54, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _BoshHolat extends StatelessWidget {
  const _BoshHolat();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(28),
    child: Center(
      child: Text(
        'Sarf darslari hali yuklanmadi. Internetga ulanib, ilovani qayta '
        'oching — darslar saytdan olinadi.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54, height: 1.4),
      ),
    ),
  );
}

/// Bitta sarf darsi.
class SarfLessonScreen extends StatelessWidget {
  final SarfLesson lesson;
  const SarfLessonScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${lesson.num}-dars')),
      // Matn ustuni cheklanadi — keng ekranda satr cho'zilib ketmasin.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Center(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    lesson.titleAr,
                    textAlign: TextAlign.center,
                    style: AppTheme.arabic(
                      size: 26,
                      color: AppColors.indigo,
                      w: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  lesson.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final b in lesson.blocks) ...[
                _blok(b),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              MasteryCallToAction(
                lessonId: lesson.completionId,
                what: 'atamalar va misollar',
                onStart: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MashqEkran(
                      sarlavha: '${lesson.num}-dars mashqi',
                      darsniki: MashqBank.sarfDars(lesson),
                      oldingilar: MashqBank.sarfGacha(lesson),
                      darsId: lesson.completionId,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blok(SarfBlock b) {
    switch (b.type) {
      case 'misol':
        return _Misol(block: b);
      case 'list':
        return _Royxat(block: b);
      default:
        return AralashMatn(b.uz);
    }
  }
}

/// Alohida turgan arabcha satr — o'qib berish tugmasi bilan.
class _Misol extends StatelessWidget {
  final SarfBlock block;
  const _Misol({required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpeakButton(text: block.ar, id: 'sarf-${block.ar}', size: 18),
              const SizedBox(width: 6),
              Expanded(child: AralashMatn(block.ar, arabchaOlchami: 24)),
            ],
          ),
          if (block.uz.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                block.uz,
                style: const TextStyle(color: Colors.black54, height: 1.35),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Royxat extends StatelessWidget {
  final SarfBlock block;
  const _Royxat({required this.block});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.intro.isNotEmpty) ...[
          AralashMatn(block.intro),
          const SizedBox(height: 6),
        ],
        for (var i = 0; i < block.items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: Text(
                    '${i + 1}.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                Expanded(child: AralashMatn(block.items[i])),
              ],
            ),
          ),
      ],
    );
  }
}
