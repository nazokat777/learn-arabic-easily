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
      // Chalg'ituvchi javoblar (boshqa harflar nomlari)
      final distractors = (List<Letter>.from(repo.letters)..shuffle(rnd))
          .where((x) => x.id != L.id)
          .take(3)
          .map((x) => x.nameUz)
          .toList();
      final options = [L.nameUz, ...distractors]..shuffle(rnd);
      return Question(
        promptLabel: 'Bu qaysi harf?',
        prompt: Text(L.ar, style: AppTheme.arabic(size: 96, color: AppColors.emerald)),
        options: options,
        correct: options.indexOf(L.nameUz),
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
