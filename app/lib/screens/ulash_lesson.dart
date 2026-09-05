import 'package:flutter/material.dart';

import '../arabic.dart';
import '../content.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets/mastery_badge.dart';
import '../widgets/speak_button.dart';
import 'ulash_test.dart';

/// «Harflarni ulash» — arab yozuvidagi eng muhim ko'nikma.
///
/// Nega alohida dars kerak: harflarni bittalab tanish yetmaydi. Arab
/// yozuvida harf so'zning qayerida turishiga qarab SHAKLINI o'zgartiradi
/// va qo'shnisiga bog'lanadi. Buni bilmagan o'quvchi «بـ» ni ko'rib, uni
/// «ب» ekanini tanimaydi va o'qiy olmaydi.
///
/// Dars oddiydan murakkabgacha 5 bosqichga bo'lingan (kontent
/// `assets/content/ulash.json` da, `.qiroat_render/build_ulash.py`
/// yasaydi). So'zlar o'ylab topilmagan — ilovaning o'z lug'atidan
/// olingan, shuning uchun har birining ma'nosi ham, ovozi ham bor.
class UlashLesson extends StatelessWidget {
  const UlashLesson({super.key});

  @override
  Widget build(BuildContext context) {
    final stages = repo.ulashStages;
    return Scaffold(
      appBar: AppBar(title: const Text('Harflarni ulash')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _QoidaCard(),
          const SizedBox(height: 18),
          if (stages.isEmpty)
            const Text('Dars hali yuklanmagan.',
                style: TextStyle(color: Colors.black54))
          else
            for (final st in stages) _stageTile(context, st),
        ],
      ),
    );
  }

  Widget _stageTile(BuildContext context, UlashStage st) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => UlashStageScreen(stage: st))),
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
                      child: Text('${st.num}',
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
                        Text(st.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text("${st.words.length} ta so'z",
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  MasteryBadge(lessonId: ulashLessonId(st.num), size: 22),
                  const Icon(Icons.chevron_right, color: AppColors.emerald),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Darsning o'zak qoidasi — oltita harf chapga ulanmaydi.
class _QoidaCard extends StatelessWidget {
  const _QoidaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.gold.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📌 ', style: TextStyle(fontSize: 15)),
              Text('Asosiy qoida',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Arab yozuvida harflar bir-biriga ulanadi. Lekin oltita harf "
            "o'zidan KEYINGI harfga ulanmaydi — ular zanjirni uzadi:",
            style: TextStyle(color: AppColors.ink, height: 1.4, fontSize: 13.5),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final h in const ['ا', 'د', 'ذ', 'ر', 'ز', 'و'])
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(h,
                          style:
                              AppTheme.arabic(size: 28, color: AppColors.gold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Qolgan harflar esa qo'shnisiga bog'lanib, shaklini o'zgartiradi. "
            "Shuning uchun bitta harf so'z boshida, o'rtasida va oxirida "
            "boshqa-boshqa ko'rinadi.",
            style: TextStyle(color: Colors.black54, height: 1.4, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Bitta bosqich: izoh + so'zlar + test.
class UlashStageScreen extends StatelessWidget {
  final UlashStage stage;
  const UlashStageScreen({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${stage.num}-bosqich')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Text(stage.titleAr,
                textDirection: TextDirection.rtl,
                style: AppTheme.arabic(
                    size: 26, color: AppColors.emerald, w: FontWeight.w700)),
          ),
          Center(
            child: Text(stage.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.black54)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(stage.explain,
                style: const TextStyle(
                    color: AppColors.ink, height: 1.4, fontSize: 13.5)),
          ),
          const SizedBox(height: 16),
          for (final w in stage.words) _WordCard(word: w),
          const SizedBox(height: 16),
          MasteryCallToAction(
            lessonId: ulashLessonId(stage.num),
            what: "${stage.words.length} ta so'z",
            onStart: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => UlashTest(stage: stage))),
          ),
        ],
      ),
    );
  }
}

/// Bitta so'z: ajratilgan harflar → ulangan so'z → ma'nosi.
///
/// Ulanmaydigan harf OLTIN rangda ko'rsatiladi — o'quvchi zanjir qayerda
/// uzilishini ko'zi bilan ko'rib turadi, qoidani yodlashi shart emas.
class _WordCard extends StatelessWidget {
  final UlashWord word;
  const _WordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    final letters = splitLetters(word.ar);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < letters.length; i++) ...[
                    Text(letters[i],
                        style: AppTheme.arabic(
                            size: 26,
                            color: ulanadi(letters[i])
                                ? AppColors.ink
                                : AppColors.gold)),
                    if (i < letters.length - 1)
                      const Text('+',
                          style: TextStyle(
                              color: Colors.black26,
                              fontWeight: FontWeight.w700)),
                  ],
                  const Text('  =  ',
                      style: TextStyle(
                          color: Colors.black26, fontWeight: FontWeight.w700)),
                  Text(word.ar,
                      style:
                          AppTheme.arabic(size: 30, color: AppColors.emerald)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                SpeakButton(text: word.ar, id: 'ulash-${word.ar}', size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(word.uz,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
