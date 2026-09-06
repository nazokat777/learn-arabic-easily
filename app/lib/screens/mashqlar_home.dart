import 'package:flutter/material.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets/mastery_badge.dart';
import '../widgets/premium_tile.dart';
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
            _tile(
              context,
              id: 'vocab_test',
              mastery: true,
              icon: Icons.menu_book_rounded,
              accent: AppColors.emerald,
              title: 'Lug\'at testi',
              sub: 'Arabcha so\'z → o\'zbekcha ma\'no',
              page: const VocabTest(),
            ),
            _tile(
              context,
              id: 'word_game',
              icon: Icons.extension_rounded,
              accent: AppColors.amber,
              title: 'So\'z yasash o\'yini',
              sub: 'Harflardan to\'g\'ri so\'zni tuzing',
              page: const WordGame(),
            ),
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
        Icon(Icons.psychology_rounded, size: 28, color: AppColors.emerald),
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
  Widget _tile(
    BuildContext context, {
    required String id,
    required IconData icon,
    required Color accent,
    required String title,
    required String sub,
    required Widget page,
    bool mastery = false,
  }) {
    final done = progress.isCompleted(id);
    return PremiumTile(
      title: title,
      subtitle: sub,
      icon: icon,
      accent: accent,
      trailing: mastery
          ? MasteryBadge(lessonId: id, size: 22)
          : done
          ? const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 22,
              ),
            )
          : null,
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
