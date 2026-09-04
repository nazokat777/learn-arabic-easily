// Testdan o'zlashtirish belgisigacha bo'lgan bog'lanishning uchidan-uchiga
// tekshiruvi.
//
// Nega alohida kerak: recordAttempt ning o'zi unit-testlarda tekshirilgan,
// ammo test ekrani unga TO'G'RI sonlarni uzatayotgani tekshirilmagan edi.
// Aynan shu joyda xato bo'lsa, ilova "xatosiz o'tdingiz" deb belgi berib
// yuborardi va butun talab ma'nosini yo'qotardi.
//
// Savollarga `speak` berilmaydi — shunda TTS chaqirilmaydi va test
// plaginlarsiz ishlaydi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/main.dart' show progress;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/quiz_common.dart';

List<Question> _ikkiSavol() => [
      Question(
        prompt: const Text('P1'),
        promptLabel: 'Savol 1',
        options: const ['A', 'B'],
        correct: 0,
      ),
      Question(
        prompt: const Text('P2'),
        promptLabel: 'Savol 2',
        options: const ['C', 'D'],
        correct: 1,
      ),
    ];

Future<void> _ochish(WidgetTester tester, String lessonId) async {
  await tester.pumpWidget(MaterialApp(
    home: MultipleChoiceQuiz(
      title: 'Sinov',
      lessonId: lessonId,
      questions: _ikkiSavol(),
    ),
  ));
  await tester.pump();
}

void main() {
  // `progress` — main.dart dagi `late final` global; test jarayonida bir
  // marta beriladi.
  progress = Progress();

  testWidgets('hamma javob birinchi urinishda to\'g\'ri bo\'lsa — o\'zlashtirildi',
      (tester) async {
    await _ochish(tester, 'w_ok');
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('D'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    expect(progress.isMastered('w_ok'), isTrue);
    expect(progress.bestPercent('w_ok'), 100);
  });

  testWidgets('bitta xato bo\'lsa — savol qaytadi va o\'zlashtirish berilmaydi',
      (tester) async {
    await _ochish(tester, 'w_bad');

    // 1-savolga XATO javob.
    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));

    // 2-savolga to'g'ri javob.
    await tester.tap(find.text('D'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // Xato savol navbat oxiriga qaytgan bo'lishi kerak — test tugamagan.
    expect(find.text('A'), findsOneWidget,
        reason: 'xato qilingan savol qaytmadi');

    // Endi uni to'g'ri yechamiz — test tugaydi, lekin belgi berilmaydi.
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    expect(progress.isMastered('w_bad'), isFalse,
        reason: 'xatodan keyin qayta to\'g\'ri javob o\'zlashtirish bermasligi kerak');
    expect(progress.bestPercent('w_bad'), 50); // 2 tadan 1 tasi birinchi urinishda
  });
}
