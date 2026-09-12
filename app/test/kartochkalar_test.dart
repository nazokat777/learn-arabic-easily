// Kartochkalar: bosilsa ag'dariladi, «Bildim» ball beradi va keyingisiga
// o'tadi, «Bilmadim» kartani oxiriga qaytaradi; yakunda «yana» taklifi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/main.dart' show progress;
import 'package:learn_arabic/mashq/element.dart';
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/kartochkalar.dart';

MashqElement _el(String ar, String uz) => MashqElement(
  kalit: 'karta::$ar',
  ar: ar,
  uz: uz,
  darsId: 'karta-1',
  tartib: 1,
  modul: 'Sinov',
  ovoz: '',
);

void main() {
  setUpAll(() => progress = Progress());

  testWidgets('ag\'darish, bildim, bilmadim va yakun', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: KartochkalarEkrani(
          elementlar: [_el('كِتَابٌ', 'kitob'), _el('قَلَمٌ', 'qalam')],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('كِتَابٌ'), findsWidgets);
    expect(find.text('0 / 2'), findsOneWidget);

    // Bosilsa ma'nosi (orqa tomon) ko'rinadi.
    await tester.tap(find.text("Bosing — ma'nosi"));
    await tester.pump(); // FlipCard animatsiyasi keyingi kadrda boshlanadi
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('kitob'), findsOneWidget);

    final oldin = progress.xp;
    await tester.tap(find.text('Bildim'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(progress.xp, oldin + 1);
    expect(find.text('قَلَمٌ'), findsWidgets);
    expect(find.text('1 / 2'), findsOneWidget);

    // Bilmadim — karta oxiriga qaytadi, tugamaydi.
    await tester.tap(find.text('Bilmadim'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Kartochkalar tugadi'), findsOneWidget);
    expect(find.text('Bilmaganlarni yana (1)'), findsOneWidget);

    await tester.tap(find.text('Bilmaganlarni yana (1)'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('قَلَمٌ'), findsWidgets);
    await tester.tap(find.text('Bildim'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hammasini bildingiz!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
