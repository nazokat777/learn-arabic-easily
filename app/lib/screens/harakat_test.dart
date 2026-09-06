import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';

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
///  2. bo'g'inni O'QISH (بِ → «bi»).
/// Ikkinchisi muhim: nomini yodlab, o'qiy olmaslik ko'p uchraydi.
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
      child: Text(
        h.exampleAr,
        style: AppTheme.arabic(size: 84, color: AppColors.emerald),
      ),
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
      questions.add(
        Question(
          promptLabel: 'Bu qaysi harakat?',
          prompt: belgi(h),
          options: opts,
          correct: opts.indexOf(h.nameUz),
          // Talaffuz javobni oshkor qilmaydi: ovoz «ba» deydi, javob esa
          // «Fatha» — shuning uchun uni oldindan eshittirsa ham bo'ladi.
          speak: h.exampleAr,
        ),
      );
    }

    // 2-tur: bo'g'inni o'qish.
    //
    // Ekranda «بِ» turadi — bu bitta belgi emas, BO'G'IN: «ب» harfi va
    // ostidagi kasra. U «bi» deb o'qiladi. Savol shuni so'raydi va
    // variantlar ham bo'g'in bo'ladi: bi, ba, bu, bun...
    //
    // Ilgari bu tur ikki marta noto'g'ri qo'yilgan edi va ikkalasida ham
    // o'quvchi to'g'ri javobni topa olmadi: avval «bu belgi qanday
    // o'qiladi?» deb so'ralib, variantlar unli (a, i, u) edi; keyin savol
    // «qanday unli tovush beradi?» ga o'zgartirildi, lekin ekranda baribir
    // bo'g'in turgani uchun o'quvchi «bi» ni izlab, ro'yxatda topmadi.
    // Xulosa: savol ekranda KO'RINIB TURGAN narsa haqida bo'lishi kerak.
    //
    // Shadda bu turdan chiqariladi: «بَّ» yolg'iz holda «bba» deb o'qiladi
    // — u harfni ikkilantiradi, unli bermaydi va bo'g'in mashqiga
    // to'g'ri kelmaydi. Nomini topish 1-turda baribir so'raladi.
    //
    // Misollar doim «ب» harfi bilan berilgan (harakat.json), shuning uchun
    // o'qilishi «b» + tovush; sukunda esa unli yo'q — «b».
    const shadda = 'bb';
    final bogin = all.where((h) => h.soundUz.trim() != shadda).toList();
    String oqilishi(Haraka h) {
      final t = h.soundUz.trim();
      return t == '-' ? 'b' : 'b$t';
    }

    final oqilishlar = bogin.map(oqilishi).toList();
    for (final h in bogin) {
      final togri = oqilishi(h);
      final opts = variantlar(togri, oqilishlar);
      questions.add(
        Question(
          promptLabel: 'Bu bo\'g\'in qanday o\'qiladi?',
          prompt: belgi(h),
          options: opts,
          correct: opts.indexOf(togri),
          // Bu yerda ovoz javobning O'ZI — faqat javobdan keyin.
          speak: h.exampleAr,
          speakRevealsAnswer: true,
        ),
      );
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
