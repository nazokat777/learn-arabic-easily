import 'dart:math';

import 'package:flutter/material.dart';

import '../arabic.dart';
import '../content.dart';
import '../theme.dart';
import 'quiz_common.dart';

/// Ulash darsining bosqichi uchun o'zlashtirish belgisi identifikatori.
///
/// Har bosqich alohida belgi oladi: 1-bosqichni bilish 5-bosqichni
/// bilishni anglatmaydi, ikkalasini bitta belgiga qo'shsak, belgi
/// nimani bildirishi tushunarsiz bo'lardi.
String ulashLessonId(int stage) => 'ulash_$stage';

/// «Harflarni ulash» bosqichining testi.
///
/// Ikki xil savol beriladi va ikkalasi ham ataylab tanlangan:
///  1. AJRATILGAN harflar ko'rsatiladi, ulangan so'zni topish kerak —
///     bu darsning asosiy ko'nikmasi, ya'ni harf shakli o'zgarganda
///     ham uni tanish.
///  2. Ulangan so'z ko'rsatiladi, ma'nosini topish kerak — foydalanuvchi
///     aynan shuni so'ragan edi: ulashni LUG'AT bilan birga berish.
///
/// Savollar soni 12 ta bilan cheklangan va har safar tasodifiy tanlanadi:
/// bosqichda 22 tagacha so'z bor, hammasini bitta seansda xatosiz o'tish
/// talab qilinsa, o'quvchi charchaydi. Takrorlaganda boshqa so'zlar
/// tushadi, ya'ni bosqich baribir to'liq qamraladi.
class UlashTest extends StatelessWidget {
  final UlashStage stage;
  const UlashTest({super.key, required this.stage});

  static const int _maxQuestions = 12;

  @override
  Widget build(BuildContext context) {
    final rnd = Random();
    final words = List<UlashWord>.from(stage.words)..shuffle(rnd);
    final picked = words.take(_maxQuestions).toList();

    final hammaAr = stage.words.map((w) => w.ar).toList();
    final hammaUz = stage.words.map((w) => w.uz).toList();

    List<String> variantlar(String togri, List<String> hammasi) {
      final chalgituvchi = hammasi.where((x) => x != togri).toSet().toList()
        ..shuffle(rnd);
      return <String>[togri, ...chalgituvchi.take(3)]..shuffle(rnd);
    }

    final questions = <Question>[];
    for (var i = 0; i < picked.length; i++) {
      final w = picked[i];
      // Savol turlari navbatlashadi — bittasi zeriktirmasin.
      if (i.isEven) {
        final opts = variantlar(w.ar, hammaAr);
        questions.add(Question(
          promptLabel: 'Bu harflar qaysi so\'zni beradi?',
          prompt: _AjratilganHarflar(word: w.ar),
          options: opts,
          correct: opts.indexOf(w.ar),
          arabicOptions: true,
          // Ovoz javobni oshkor qiladi (variantlar — yozilgan so'zlar),
          // shuning uchun faqat javobdan keyin eshittiriladi.
          speak: w.ar,
          speakRevealsAnswer: true,
        ));
      } else {
        final opts = variantlar(w.uz, hammaUz);
        questions.add(Question(
          promptLabel: 'Bu so\'zning ma\'nosi nima?',
          prompt: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(w.ar,
                style: AppTheme.arabic(size: 46, color: AppColors.emerald)),
          ),
          options: opts,
          correct: opts.indexOf(w.uz),
          // Bu yerda ovoz javobni oshkor qilmaydi: eshitilgani arabcha,
          // variantlar esa o'zbekcha.
          speak: w.ar,
        ));
      }
    }
    questions.shuffle(rnd);

    return MultipleChoiceQuiz(
      title: '${stage.num}-bosqich — test',
      lessonId: ulashLessonId(stage.num),
      questions: questions,
      xpPerCorrect: 5,
    );
  }
}

/// So'zni ajratilgan harflar ko'rinishida ko'rsatadi: «بَ + ا + بٌ».
///
/// Har harf alohida `Text` ichida turadi — shuning uchun shrift ularni
/// bir-biriga ULAMAYDI va o'quvchi harflarning yolg'iz shaklini ko'radi.
/// Aynan shu savolning mohiyati: yolg'iz shakldan ulangan so'zni tanish.
class _AjratilganHarflar extends StatelessWidget {
  final String word;
  const _AjratilganHarflar({required this.word});

  @override
  Widget build(BuildContext context) {
    final letters = splitLetters(word);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < letters.length; i++) ...[
            Text(letters[i],
                style: AppTheme.arabic(size: 40, color: AppColors.ink)),
            if (i < letters.length - 1)
              const Text('+',
                  style: TextStyle(
                      color: Colors.black26,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}
