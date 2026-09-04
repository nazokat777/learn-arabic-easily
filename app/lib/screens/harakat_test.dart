import 'dart:math';

import 'package:flutter/material.dart';

import '../content.dart';
import '../main.dart';
import '../theme.dart';
import 'quiz_common.dart';

/// Harakatlar darsining testi.
///
/// Nega kerak edi: harakatlar darsi yagona bo'lim ediki, unda test umuman
/// yo'q edi — o'quvchi kartochkalarni ko'rib chiqib, hech narsa
/// tekshirilmasdan «o'rgandim» deb ketardi. Holbuki harakatni tanimasdan
/// arabcha matnni to'g'ri o'qib bo'lmaydi.
///
/// Ikki xil savol beriladi:
///  1. belgini KO'RIB nomini topish (بَ → Fatha);
///  2. belgining qanday O'QILISHINI topish (بِ → «i»).
/// Ikkinchisi muhim: nomini yodlab, tovushini bilmaslik ko'p uchraydi.
class HarakatTest extends StatelessWidget {
  const HarakatTest({super.key});

  static const String lessonId = 'harakat_test';

  @override
  Widget build(BuildContext context) {
    final rnd = Random();
    final all = repo.harakat;
    final questions = <Question>[];

    Widget belgi(Haraka h) => Directionality(
          textDirection: TextDirection.rtl,
          child: Text(h.exampleAr,
              style: AppTheme.arabic(size: 84, color: AppColors.emerald)),
        );

    List<String> variantlar(String togri, List<String> hammasi) {
      final chalgituvchi = hammasi.where((x) => x != togri).toList()
        ..shuffle(rnd);
      return <String>[togri, ...chalgituvchi.take(3)]..shuffle(rnd);
    }

    // 1-tur: belgi → nomi
    final nomlar = all.map((h) => h.nameUz).toList();
    for (final h in all) {
      final opts = variantlar(h.nameUz, nomlar);
      questions.add(Question(
        promptLabel: 'Bu qaysi harakat?',
        prompt: belgi(h),
        options: opts,
        correct: opts.indexOf(h.nameUz),
        // Talaffuz javobni oshkor qilmaydi: ovoz «ba» deydi, javob esa
        // «Fatha» — shuning uchun uni oldindan eshittirsa ham bo'ladi.
        speak: h.exampleAr,
      ));
    }

    // 2-tur: belgi → tovushi. Sukunni tashlab ketamiz: uning «tovushi»
    // varianti «tovush yo'q (sukun)» bo'lib, javobni o'zi aytib qo'yadi.
    final tovushli = all.where((h) => h.soundUz.trim() != '-').toList();
    final tovushlar = tovushli.map((h) => h.soundUz).toList();
    for (final h in tovushli) {
      final opts = variantlar(h.soundUz, tovushlar);
      questions.add(Question(
        promptLabel: 'Bu belgi qanday o\'qiladi?',
        prompt: belgi(h),
        options: opts,
        correct: opts.indexOf(h.soundUz),
        // Bu yerda ovoz javobning O'ZI — faqat javobdan keyin.
        speak: h.exampleAr,
        speakRevealsAnswer: true,
      ));
    }

    questions.shuffle(rnd);
    return MultipleChoiceQuiz(
      title: 'Harakatlar testi',
      lessonId: lessonId,
      questions: questions,
      xpPerCorrect: 5,
    );
  }
}
