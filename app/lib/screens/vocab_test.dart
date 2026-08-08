import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import '../content.dart';
import '../theme.dart';
import 'quiz_common.dart';

class VocabTest extends StatelessWidget {
  const VocabTest({super.key});

  @override
  Widget build(BuildContext context) {
    final rnd = Random();
    final words = List<VocabWord>.from(repo.words)..shuffle(rnd);
    final pick = words.take(10).toList();

    final questions = pick.map((w) {
      final distractors = (List<VocabWord>.from(repo.words)..shuffle(rnd))
          .where((x) => x.id != w.id)
          .take(3)
          .map((x) => x.uz)
          .toList();
      final options = [w.uz, ...distractors]..shuffle(rnd);
      return Question(
        promptLabel: 'Bu so\'z nima degani?',
        prompt: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(w.ar, style: AppTheme.arabic(size: 64, color: AppColors.emerald)),
        ),
        options: options,
        correct: options.indexOf(w.uz),
        speak: w.ar,
      );
    }).toList();

    return MultipleChoiceQuiz(
      title: 'Lug\'at testi',
      lessonId: 'vocab_test',
      questions: questions,
      xpPerCorrect: 6,
    );
  }
}
