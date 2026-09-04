import 'package:flutter/material.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets/mastery_badge.dart';
import 'vocab_test.dart';
import 'word_game.dart';

/// «Mashqlar» — lug'at testi va so'z yasash o'yini (o'rganilgan so'zlarni mustahkamlash).
class MashqlarHome extends StatelessWidget {
  const MashqlarHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mashqlar')),
      body: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _intro(),
            const SizedBox(height: 16),
            // Lug'at testi — haqiqiy test, shuning uchun belgisi ham
            // o'zlashtirish belgisi: xatosiz o'tilmaguncha berilmaydi.
            _tile(context,
                id: 'vocab_test',
                mastery: true,
                emoji: '📚',
                title: 'Lug\'at testi',
                sub: 'Arabcha so\'z → o\'zbekcha ma\'no',
                page: const VocabTest()),
            _tile(context,
                id: 'word_game',
                emoji: '🧩',
                title: 'So\'z yasash o\'yini',
                sub: 'Harflardan to\'g\'ri so\'zni tuzing',
                page: const WordGame()),
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
        child: const Row(
          children: [
            Text('🧠', style: TextStyle(fontSize: 26)),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'O\'rgangan so\'zlaringizni test va o\'yin orqali mustahkamlang.',
                style: TextStyle(color: AppColors.ink, height: 1.35),
              ),
            ),
          ],
        ),
      );

  /// [mastery] — belgi o'zlashtirish (xatosiz test) bo'yicha ko'rsatilsinmi.
  /// So'z yasash o'yinida bu ma'nosiz: unda belgilangan savollar to'plami
  /// yo'q, shuning uchun u eski «bajarildi» belgisida qoladi.
  Widget _tile(BuildContext context,
      {required String id,
      required String emoji,
      required String title,
      required String sub,
      required Widget page,
      bool mastery = false}) {
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
                if (mastery)
                  MasteryBadge(lessonId: id, size: 22)
                else if (done)
                  const Icon(Icons.check_circle, color: AppColors.success),
                const Icon(Icons.chevron_right, color: AppColors.emerald),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
