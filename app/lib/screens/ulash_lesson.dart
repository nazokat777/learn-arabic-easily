import 'package:flutter/material.dart';

import '../arabic.dart';
import '../content.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets/mastery_badge.dart';
import '../widgets/premium_tile.dart';
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
            const Text(
              'Dars hali yuklanmagan.',
              style: TextStyle(color: Colors.black54),
            )
          else
            for (final st in stages) _stageTile(context, st),
        ],
      ),
    );
  }

  Widget _stageTile(BuildContext context, UlashStage st) => PremiumTile(
    title: st.title,
    subtitle: "${st.words.length} ta so'z",
    label: '${st.num}',
    accent: AppColors.amber,
    trailing: MasteryBadge(lessonId: ulashLessonId(st.num), size: 22),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UlashStageScreen(stage: st)),
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
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📌 ', style: TextStyle(fontSize: 15)),
              Text(
                'Asosiy qoida',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                  fontSize: 13,
                ),
              ),
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
                        color: AppColors.gold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        h,
                        style: AppTheme.arabic(size: 28, color: AppColors.gold),
                      ),
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
            child: Text(
              stage.titleAr,
              textDirection: TextDirection.rtl,
              style: AppTheme.arabic(
                size: 26,
                color: AppColors.emerald,
                w: FontWeight.w700,
              ),
            ),
          ),
          Center(
            child: Text(
              stage.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              stage.explain,
              style: const TextStyle(
                color: AppColors.ink,
                height: 1.4,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final w in stage.words) _WordCard(word: w),
          const SizedBox(height: 16),
          MasteryCallToAction(
            lessonId: ulashLessonId(stage.num),
            what: "${stage.words.length} ta so'z",
            onStart: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UlashTest(stage: stage)),
            ),
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
///
/// Kartochka bosilsa, har harfning shu so'zdagi HOLATI va o'sha joyda
/// qanday chizilishi ochiladi. Aynan shu bilim yetishmasa, o'quvchi
/// «بـ» ni ko'rib uni «ب» ekanini tanimaydi.
class _WordCard extends StatelessWidget {
  final UlashWord word;
  const _WordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    final letters = splitLetters(word.ar);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showHarfSheet(context, word),
          // Ataylab rangsiz: fonni Material chizadi. Bu yerga oq fon
          // qo'yilsa, bosish to'lqini (ripple) uning ostida qolib
          // ko'rinmaydi va kartochka bosilmaydigandek tuyuladi.
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        Text(
                          letters[i],
                          style: AppTheme.arabic(
                            size: 26,
                            color: ulanadi(letters[i])
                                ? AppColors.ink
                                : AppColors.gold,
                          ),
                        ),
                        if (i < letters.length - 1)
                          const Text(
                            '+',
                            style: TextStyle(
                              color: Colors.black26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                      const Text(
                        '  =  ',
                        style: TextStyle(
                          color: Colors.black26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        word.ar,
                        style: AppTheme.arabic(
                          size: 30,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SpeakButton(
                      text: word.ar,
                      id: 'ulash-${word.ar}',
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        word.uz,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Har harfning so'zdagi holati va o'sha joydagi shakli.
void _showHarfSheet(BuildContext context, UlashWord word) {
  final letters = splitLetters(word.ar);
  final holatlar = harfHolatlari(letters);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    // Olti harfli so'zda ro'yxat past ekranga sig'may qoladi — shuning
    // uchun oyna balandligi cheklanmaydi va ichi aylanadi.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    word.ar,
                    style: AppTheme.arabic(size: 44, color: AppColors.emerald),
                  ),
                ),
              ),
              Center(
                child: Text(
                  word.uz,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Harflar so\'zda qanday chiziladi:',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < letters.length; i++)
                _HarfRow(
                  letter: letters[i],
                  holat: holatlar[i],
                  tartib: i + 1,
                  oxirgi: i == letters.length - 1,
                ),
              const SizedBox(height: 12),
              Text(
                "«${stripDiacritics(word.ar)}» — ${letters.length} harf. "
                'Oltin rangdagi harf o\'zidan keyingisiga ulanmaydi.',
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HarfRow extends StatelessWidget {
  final String letter;
  final HarfHolati holat;
  final int tartib;

  /// So'zning oxirgi harfimi.
  ///
  /// Kerak, chunki oxirgi harf uchun «keyingi harfga ulanadi» degan izoh
  /// ma'nosiz: undan keyin harf yo'q. Bu izoh o'quvchiga noto'g'ri
  /// tasavvur berardi.
  final bool oxirgi;

  const _HarfRow({
    required this.letter,
    required this.holat,
    required this.tartib,
    required this.oxirgi,
  });

  @override
  Widget build(BuildContext context) {
    final ulanar = ulanadi(letter);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$tartib.',
              style: const TextStyle(
                color: Colors.black26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                holatShakli(letter, holat),
                style: AppTheme.arabic(
                  size: 30,
                  color: ulanar ? AppColors.ink : AppColors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holatNomi(holat),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  oxirgi
                      ? "so'z shu yerda tugaydi"
                      : ulanar
                      ? "keyingi harfga ulanadi"
                      : "keyingi harfga ULANMAYDI",
                  style: TextStyle(
                    fontSize: 12,
                    color: (ulanar || oxirgi) ? Colors.black45 : AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            stripDiacritics(letter),
            style: AppTheme.arabic(size: 24, color: Colors.black26),
          ),
        ],
      ),
    );
  }
}
