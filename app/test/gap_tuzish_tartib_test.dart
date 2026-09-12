// Gap tuzish: haqiqiy kitob juftligi bilan — so'zlar o'ngdan chapga
// joylashadi (birinchi tanlangan o'ngda) va to'g'ri tartib to'g'ri deb
// baholanadi.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/main.dart' show progress;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/lesson/gap_tuzish.dart';

void main() {
  setUpAll(() => progress = Progress());

  testWidgets("o'ngdan chapga joylashuv va to'g'ri baho", (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const juftlar = [('Daftarni ber.', 'هَاتِ الكُرَّاسَةَ.')];
    var ball = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GapTuzish(
              juftlar: juftlar,
              award: (x) => ball += x,
              onDone: () {},
              rnd: Random(1),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Havzada: birinchi so'z (هَاتِ) o'ngda turishi shart emas (aralash),
    // lekin tanlangach javob maydonida birinchi tanlangan O'NGDA bo'ladi.
    await tester.tap(find.text('هَاتِ'));
    await tester.pump();
    await tester.tap(find.text('الكُرَّاسَةَ.'));
    await tester.pump();
    final x1 = tester.getCenter(find.text('هَاتِ')).dx;
    final x2 = tester.getCenter(find.text('الكُرَّاسَةَ.')).dx;
    expect(x1, greaterThan(x2), reason: 'birinchi tanlangan so\'z o\'ngda');

    await tester.tap(find.widgetWithText(FilledButton, 'Tekshirish'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(ball, 2, reason: 'to\'g\'ri tartib ball berishi kerak');
    expect(find.text('Tugatish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
