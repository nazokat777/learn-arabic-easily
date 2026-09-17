import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';
import '../main.dart';
import '../content.dart';
import '../theme.dart';
import 'quiz_common.dart';

class LetterTest extends StatelessWidget {
  const LetterTest({super.key});

  @override
  Widget build(BuildContext context) {
    final rnd = Random();
    // Alifboni «bilish» — 28 harfning hammasini tanish demak. Ilgari
    // tasodifiy 10 tasi so'ralardi, ya'ni 18 harfni bilmagan o'quvchi ham
    // testdan o'tib ketishi mumkin edi.
    final pick = List<Letter>.from(repo.letters)..shuffle(rnd);

    // Ikki xil savol almashib keladi: ko'rib nomini topish va nomini
    // ESHITIB harfni topish — ikkinchisi inson ovozidagi harf nomlari
    // bilan quloqni o'rgatadi (faqat ko'z bilan tanish yetarli emas).
    var n = 0;
    final questions = pick.map((L) {
      final tinglash = (n++).isOdd;
      if (tinglash) return _tinglashSavoli(L, rnd);
      // Chalg'ituvchi javoblar (boshqa harflar nomlari).
      //
      // Nomi bo'yicha solishtiramiz, id bo'yicha emas: ح va ه ning o'zbekcha
      // nomi bir xil — «Haa». id bo'yicha filtrlaganda ikkita bir xil variant
      // chiqib, biri «xato» deb belgilanardi.
      final distractors = <String>[];
      for (final x in List<Letter>.from(repo.letters)..shuffle(rnd)) {
        if (distractors.length == 3) break;
        if (x.nameUz != L.nameUz && !distractors.contains(x.nameUz)) {
          distractors.add(x.nameUz);
        }
      }
      final options = [L.nameUz, ...distractors]..shuffle(rnd);
      return Question(
        promptLabel: 'Bu qaysi harf?',
        prompt: Text(
          L.ar,
          style: AppTheme.arabic(size: 96, color: AppColors.emerald),
        ),
        options: options,
        correct: options.indexOf(L.nameUz),
        // Javobdan KEYIN harf nomi o'qiladi — nomning o'zi javob bo'lgani
        // uchun oldin eshittirib bo'lmaydi.
        speak: L.nameAr,
        speakRevealsAnswer: true,
      );
    }).toList();

    return MultipleChoiceQuiz(
      title: 'Harflar testi',
      lessonId: 'letter_test',
      questions: questions,
      xpPerCorrect: 5,
    );
  }

  /// «Tinglang — qaysi harf?»: nomi o'qiladi, variantlar arab harflari.
  Question _tinglashSavoli(Letter L, Random rnd) {
    final distractors = <String>[];
    for (final x in List<Letter>.from(repo.letters)..shuffle(rnd)) {
      if (distractors.length == 3) break;
      if (x.ar != L.ar && !distractors.contains(x.ar)) distractors.add(x.ar);
    }
    final options = [L.ar, ...distractors]..shuffle(rnd);
    return Question(
      promptLabel: 'Tinglang: qaysi harf?',
      prompt: const Icon(
        Icons.hearing_rounded,
        size: 72,
        color: AppColors.emerald,
      ),
      options: options,
      correct: options.indexOf(L.ar),
      arabicOptions: true,
      // Nom javobni oshkor qilmaydi — variantlar harflarning o'zi.
      speak: L.nameAr,
      speakOnShow: true,
    );
  }
}
