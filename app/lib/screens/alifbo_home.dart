import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';
import '../main.dart';
import '../mashq/bank.dart';
import '../mashq/element.dart';
import '../mashq/mashq_ekran.dart';
import '../theme.dart';
import 'letters_lesson.dart';
import 'letter_test.dart';
import 'harakat_lesson.dart';
import 'harakat_test.dart';
import 'ulash_lesson.dart';
import '../widgets/mastery_badge.dart';
import '../widgets/premium_tile.dart';

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
            // Har mavzu = dars + test. Belgi (✅ yoki foiz) MAVZUniki,
            // shuning uchun dars va test kartochkalari bitta o'zlashtirish
            // holatini ko'rsatadi — o'quvchi mavzuni bilishini bir joydan
            // ko'radi.
            _tile(
              context,
              masteryId: 'letter_test',
              arabic: 'أ',
              accent: AppColors.emerald,
              title: 'Harflar darsi',
              sub: '28 harf — nomi, maxraj va holatlari',
              page: const LettersLesson(),
            ),
            _tile(
              context,
              masteryId: 'letter_test',
              icon: Icons.quiz_rounded,
              accent: AppColors.emerald,
              title: 'Harflar testi',
              sub: "28 harfning hammasi — xatosiz o'tilishi kerak",
              page: const LetterTest(),
            ),
            _mashqTile(
              context,
              accent: AppColors.emerald,
              title: 'Harflar mashqi',
              sub: "Har bir harf 100% bo'lguncha qaytariladi",
              sarlavha: 'Harflar mashqi',
              darsniki: MashqBank.harflar,
              oldingilar: MashqBank.harflar,
              darsId: 'letter_test',
            ),
            _tile(
              context,
              masteryId: 'harakat_test',
              arabic: 'بَ',
              accent: AppColors.teal,
              title: 'Harakatlar darsi',
              sub: 'Fatha, kasra, zamma, sukun, shadda, tanvin',
              page: const HarakatLesson(),
            ),
            _tile(
              context,
              masteryId: 'harakat_test',
              icon: Icons.quiz_rounded,
              accent: AppColors.teal,
              title: 'Harakatlar testi',
              sub: "Belgini tanish va qanday o'qilishini bilish",
              page: const HarakatTest(),
            ),
            _mashqTile(
              context,
              accent: AppColors.teal,
              title: 'Harakatlar mashqi',
              sub: "Harakatlar, so'ngra harflar bilan aralash takror",
              sarlavha: 'Harakatlar mashqi',
              darsniki: MashqBank.harakatlar,
              oldingilar: MashqBank.alifboGacha,
              darsId: 'harakat_test',
            ),
            const SizedBox(height: 4),
            const Divider(height: 24),
            _tile(
              context,
              masteryId: 'ulash_1',
              icon: Icons.link_rounded,
              accent: AppColors.amber,
              title: 'Harflarni ulash',
              sub: "Harflarni bog'lab o'qish — 5 bosqich, 89 ta so'z",
              page: const UlashLesson(),
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
    child: Row(
      children: [
        Text(
          'أ ب ت',
          style: AppTheme.arabic(size: 28, color: AppColors.emerald),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Arab harflarini va ularning tovushlarini (maxraj) noldan o\'rganasiz.',
            style: TextStyle(color: AppColors.ink, height: 1.35),
          ),
        ),
      ],
    ),
  );

  /// Mashq kartochkasi.
  ///
  /// Elementlar `onTap` ichida yasaladi (funksiya ko'rinishida beriladi):
  /// ro'yxat har qayta chizilganda 28 ta harfdan element yig'ish bekorga
  /// ish bo'lardi.
  Widget _mashqTile(
    BuildContext context, {
    required Color accent,
    required String title,
    required String sub,
    required String sarlavha,
    required List<MashqElement> Function() darsniki,
    required List<MashqElement> Function() oldingilar,
    required String darsId,
  }) {
    return PremiumTile(
      title: title,
      subtitle: sub,
      icon: Icons.psychology_alt_rounded,
      accent: accent,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MashqEkran(
            sarlavha: sarlavha,
            darsniki: darsniki(),
            oldingilar: oldingilar(),
            darsId: darsId,
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String masteryId,
    IconData? icon,
    String? arabic,
    required Color accent,
    required String title,
    required String sub,
    required Widget page,
  }) {
    return PremiumTile(
      title: title,
      subtitle: sub,
      icon: icon,
      arabic: arabic,
      accent: accent,
      trailing: MasteryBadge(lessonId: masteryId, size: 22),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
