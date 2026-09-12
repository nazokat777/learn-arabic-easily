// Gap tuzish: so'zlar aralashadi, to'g'ri tartibda bosilsa ball va
// keyingi gap; xato bo'lsa to'g'ri javob ko'rsatiladi; oxirida onDone.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/main.dart' show progress;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/lesson/gap_tuzish.dart';

void main() {
  setUpAll(() => progress = Progress());

  test("so'zlarga bo'lish", () {
    expect(GapTuzish.sozlar('هَذَا كُرْسِيٌّ.'), ['هَذَا', 'كُرْسِيٌّ.']);
    expect(GapTuzish.sozlar('  أَيْنَ   الدَّفْتَرُ؟ '), [
      'أَيْنَ',
      'الدَّفْتَرُ؟',
    ]);
  });

  testWidgets("to'g'ri tartib — ball; xato — javob; oxirida tugaydi", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const juftlar = [
      ('Bu kursi.', 'هَذَا كُرْسِيٌّ.'),
      ('Daftar qaerda?', 'أَيْنَ الدَّفْتَرُ؟'),
    ];
    var ball = 0;
    var tugadi = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GapTuzish(
              juftlar: juftlar,
              award: (x) => ball += x,
              onDone: () => tugadi++,
              rnd: Random(3),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Bu kursi.'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    // Havzadagi ikkala so'z ko'rinadi; tekshirish hali o'chiq.
    expect(find.text('هَذَا'), findsOneWidget);
    expect(find.text('كُرْسِيٌّ.'), findsOneWidget);
    final tekshir = find.widgetWithText(FilledButton, 'Tekshirish');
    expect(tester.widget<FilledButton>(tekshir).onPressed, isNull);

    // To'g'ri tartibda bosamiz.
    await tester.tap(find.text('هَذَا'));
    await tester.pump();
    await tester.tap(find.text('كُرْسِيٌّ.'));
    await tester.pump();
    expect(tester.widget<FilledButton>(tekshir).onPressed, isNotNull);
    await tester.tap(tekshir);
    await tester.pump(const Duration(milliseconds: 300));
    expect(ball, 2);
    expect(find.text('Keyingi gap'), findsOneWidget);

    await tester.tap(find.text('Keyingi gap'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Daftar qaerda?'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);

    // Noto'g'ri tartib: javob ko'rsatiladi, ball qo'shilmaydi.
    await tester.tap(find.text('الدَّفْتَرُ؟'));
    await tester.pump();
    await tester.tap(find.text('أَيْنَ'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Tekshirish'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(ball, 2);
    expect(find.textContaining("To'g'ri javob"), findsOneWidget);
    await tester.tap(find.text('Tugatish'));
    await tester.pump();
    expect(tugadi, 1);
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
  });
}
