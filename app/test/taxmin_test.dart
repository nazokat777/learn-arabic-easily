// Lug'at bosqichida TAXMIN (pretesting): ma'no ochilishidan oldin 3 variant;
// to'g'ri taxmin +1 ball va «sezgi» xabari, noto'g'ri — ta'nasiz, so'z
// baribir ochiladi; keyin «Keyingi so'z».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/lesson/vocab_flow.dart';

void main() {
  progress = Progress();

  final dars = QiroatLesson(
    book: 1,
    num: 99,
    titleAr: 'x',
    reading: '',
    vocab: const [
      QiroatVocab(ar: 'كِتَابٌ', pl: '', uz: 'kitob'),
      QiroatVocab(ar: 'قَلَمٌ', pl: '', uz: 'qalam'),
      QiroatVocab(ar: 'بَابٌ', pl: '', uz: 'eshik'),
    ],
  );

  testWidgets("taxmin: 3 variant, to'g'risi +1, keyin ochiladi", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var ball = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VocabStage(lesson: dars, onDone: () {}, award: (x) => ball += x),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text("Sizningcha, ma'nosi qaysi?"), findsOneWidget);
    expect(find.text('Bilmadim — ochish'), findsOneWidget);
    // Uch variantning hammasi darsdan.
    for (final uz in ['kitob', 'qalam', 'eshik']) {
      expect(find.text(uz), findsWidgets);
    }
    // Birinchi karta — kitob (tartib saqlanadi). To'g'ri taxmin.
    await tester.tap(find.widgetWithText(OutlinedButton, 'kitob'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(ball, 1);
    expect(find.textContaining('Sezgi kuchli'), findsOneWidget);
    expect(find.text("Keyingi so'z"), findsOneWidget);

    // Ikkinchi karta — qalam. Noto'g'ri taxmin: ball yo'q, so'z ochiladi.
    await tester.tap(find.text("Keyingi so'z"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(OutlinedButton, 'eshik'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(ball, 1);
    expect(find.textContaining('kuchliroq esda qoladi'), findsOneWidget);
    expect(find.text("Keyingi so'z"), findsOneWidget);
  });
}
