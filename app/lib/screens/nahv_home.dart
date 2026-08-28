import 'package:flutter/material.dart';

import '../main.dart';
import '../content.dart';
import '../theme.dart';
import '../widgets/entrance.dart';
import '../widgets/speak_button.dart';
import 'lesson/sentence_text.dart';

/// «Nahv» — arab tili grammatikasi (jumla tuzilishi) bo'limi.
///
/// Manba: «الدروس النحوية» — TO'LIQ arabcha kitob. Shuning uchun bu bo'lim
/// qolganlaridan bir narsa bilan farq qiladi: arabcha matn kitobniki, ammo
/// o'zbekchasi TARJIMA - kitobda o'zbekcha matn umuman yo'q. Shuning uchun
/// har bir darsda ikkalasi yonma-yon ko'rsatiladi, o'quvchi asliyatni ham
/// ko'rib tursin.
class NahvHome extends StatelessWidget {
  const NahvHome({super.key});

  @override
  Widget build(BuildContext context) {
    final lessons = repo.nahvLessons;
    return Scaffold(
      appBar: AppBar(title: const Text('Nahv')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text('نَحْو',
                    style: AppTheme.arabic(size: 30, color: AppColors.emerald)),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    '«الدروس النحوية» — jumla tuzilishi. Kitob arabcha; '
                    'o\'zbekchasi tarjima qilib berilgan.',
                    style: TextStyle(color: AppColors.ink, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (lessons.isEmpty)
            const Text('Darslar hali qo\'shilmagan.',
                style: TextStyle(color: Colors.black54))
          else
            ...lessons.asMap().entries.map((e) => EntranceFade(
                  delay: Duration(milliseconds: 40 + (e.key < 12 ? e.key : 12) * 45),
                  child: _tile(context, e.value),
                )),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, NahvLesson l) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => NahvLessonScreen(lesson: l))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.emerald, AppColors.emeraldDark]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text('${l.num}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(l.titleAr,
                            textDirection: TextDirection.rtl,
                            style: AppTheme.arabic(
                                size: 18, color: AppColors.emerald)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.emerald),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Bitta nahv darsi: qoida, izoh va misollar.
class NahvLessonScreen extends StatelessWidget {
  final NahvLesson lesson;
  const NahvLessonScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${lesson.num}-dars')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Text(lesson.titleAr,
                textDirection: TextDirection.rtl,
                style: AppTheme.arabic(
                    size: 28, color: AppColors.emerald, w: FontWeight.w700)),
          ),
          Center(
            child: Text(lesson.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.black54)),
          ),
          const SizedBox(height: 18),
          // Qoida - kitobda ramka ichida beriladi, bu yerda ham ajratib turadi.
          if (lesson.rule.ar.isNotEmpty) _RuleBox(rule: lesson.rule),
          const SizedBox(height: 18),
          for (final b in lesson.blocks) ...[
            if (b.type == 'list' && (b.intro?.ar.isNotEmpty ?? false))
              _Bilingual(pair: b.intro!),
            if (b.type != 'list') _Bilingual(pair: b.main!),
            if (b.type == 'list')
              for (var i = 0; i < b.items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 2),
                  child: _Bilingual(pair: b.items[i], bullet: '${i + 1}.'),
                ),
            const SizedBox(height: 12),
          ],
          if (lesson.exercise.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('✍️ ', style: TextStyle(fontSize: 16)),
                Text('Mashq — تَمْرِينٌ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.gold)),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < lesson.exercise.length; i++)
              _Bilingual(pair: lesson.exercise[i], bullet: '${i + 1}.'),
          ],
        ],
      ),
    );
  }
}

/// Kitobdagi ramkali qoida.
class _RuleBox extends StatelessWidget {
  final NahvPair rule;
  const _RuleBox({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📌 ', style: TextStyle(fontSize: 15)),
              const Text('Qoida',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 13)),
              const Spacer(),
              SpeakButton(text: rule.ar, id: 'nahv-qoida-${rule.ar}', size: 20),
            ],
          ),
          const SizedBox(height: 4),
          _Bilingual(pair: rule, arabicSize: 22),
        ],
      ),
    );
  }
}

/// Arabcha matn (tinglash tugmasi va bosiladigan so'zlar bilan) va uning
/// tagida o'zbekcha tarjimasi.
class _Bilingual extends StatelessWidget {
  final NahvPair pair;
  final String? bullet;
  final double arabicSize;
  const _Bilingual({required this.pair, this.bullet, this.arabicSize = 20});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bullet != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 2),
                  child: Text(bullet!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.gold)),
                ),
              SpeakButton(text: pair.ar, id: 'nahv-${pair.ar}', size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: SentenceText(
                    sentence: pair.ar, vocab: const [], reading: '', size: arabicSize),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 2),
            child: Text(pair.uz,
                style: const TextStyle(color: Colors.black54, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
