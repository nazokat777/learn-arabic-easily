// Aralash (o'zbekcha + arabcha) matn qanday joylashishini qayd etadi.
//
// Nega muhim: ilova matnni bo'laklarga bo'lib, ularni CHAPDAN O'NGGA
// joylashtiradi; faqat bo'lakning ICHI arabcha bo'lsa o'ngdan chapga
// o'qiladi. Demak kontentda misollar kitob sahifasida KO'RINADIGAN
// tartibda saqlanishi kerak.
//
// Bu tekshirilmagani uchun sarf misollari bir vaqt teskari chiqib
// qolgan edi: kitobda «ضَرَبَ – فَعَلَ vaznida», ilovada esa
// «فَعَلَ – ضَرَبَ vaznida».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/widgets/aralash_matn.dart';

/// Chizilgan matn bo'laklarini chapdan o'ngga yig'ib beradi.
List<String> _bolaklar(WidgetTester tester) {
  final natija = <String>[];
  void yur(InlineSpan s) {
    if (s is! TextSpan) return;
    final t = s.text;
    if (t != null && t.isNotEmpty) natija.add(t);
    for (final c in s.children ?? const <InlineSpan>[]) {
      yur(c);
    }
  }

  for (final e in find.byType(RichText).evaluate()) {
    yur((e.widget as RichText).text);
  }
  return natija;
}

void main() {
  testWidgets('bo\'laklar matndagi tartibda, chapdan o\'ngga chiziladi', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AralashMatn('Masalan: ضَرَبَ – فَعَلَ vaznida.')),
      ),
    );

    expect(_bolaklar(tester).map((s) => s.trim()).toList(), [
      'Masalan:',
      'ضَرَبَ',
      '–',
      'فَعَلَ',
      'vaznida.',
    ]);
  });

  testWidgets('bitta bo\'lak ichidagi arabcha o\'z holicha qoladi', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AralashMatn('Asliy harf: فاءُ، عينُ، لام dir.')),
      ),
    );

    // Ko'p so'zli arabcha ibora bitta bo'lak bo'lib qoladi — uning ichki
    // tartibi o'zgarmaydi (o'ngdan chapga o'qiladi).
    expect(_bolaklar(tester).any((s) => s.contains('فاءُ، عينُ، لام')), isTrue);
  });
}
