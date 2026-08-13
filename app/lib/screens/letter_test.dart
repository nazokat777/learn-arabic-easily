import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import '../content.dart';
import '../theme.dart';
import 'quiz_common.dart';

class LetterTest extends StatelessWidget {
  const LetterTest({super.key});

  @override
  Widget build(BuildContext context) {
    final rnd = Random();
    final letters = List<Letter>.from(repo.letters)..shuffle(rnd);
    final pick = letters.take(10).toList();

    final questions = pick.map((L) {
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
        prompt: Text(L.ar, style: AppTheme.arabic(size: 96, color: AppColors.emerald)),
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
}
