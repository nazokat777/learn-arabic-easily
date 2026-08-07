import 'package:flutter/material.dart';
import '../main.dart';
import '../theme.dart';
import 'letters_lesson.dart';
import 'letter_test.dart';
import 'harakat_lesson.dart';

/// «Alifbo» fani — harf va talaffuzni o'rgatadi (harflar, testlar, harakatlar).
class AlifboHome extends StatelessWidget {
  const AlifboHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alifbo (Harflar)')),
      body: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _intro(),
            const SizedBox(height: 16),
            _tile(context,
                id: 'letters',
                emoji: '🔤',
                title: 'Harflar darsi',
                sub: '28 harf — nomi, махраж va holatlari',
                page: const LettersLesson()),
            _tile(context,
                id: 'letter_test',
                emoji: '🎯',
                title: 'Harflar testi',
                sub: 'Harfni nomidan tanish (qayta-qayta)',
                page: const LetterTest()),
            _tile(context,
                id: 'harakat',
                emoji: '◌َ',
                title: 'Harakatlar darsi',
                sub: 'Fatha, kasra, zamma, sukun, shadda, tanvin',
                page: const HarakatLesson()),
          ],
        ),
      ),
    );
  }

  Widget _intro() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.softGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text('أ ب ت', style: AppTheme.arabic(size: 28, color: AppColors.emerald)),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Arab harflarini va ularning tovushlarini (махраж) noldan o\'rganasiz.',
                style: TextStyle(color: AppColors.ink, height: 1.35),
              ),
            ),
          ],
        ),
      );

  Widget _tile(BuildContext context,
      {required String id,
      required String emoji,
      required String title,
      required String sub,
      required Widget page}) {
    final done = progress.isCompleted(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
                      const SizedBox(height: 3),
                      Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
                    ],
                  ),
                ),
                if (done)
                  const Icon(Icons.check_circle, color: AppColors.success)
                else
                  const Icon(Icons.chevron_right, color: AppColors.emerald),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
