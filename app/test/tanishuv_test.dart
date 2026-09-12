// Tanishuv: birinchi ochilishda 3 qadamli oyna chiqadi, «Boshladik!» dan
// keyin yopiladi va qayta ko'rsatilmaydi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/home.dart';

void main() {
  progress = Progress();
  repo = ContentRepository();

  testWidgets('tanishuv bir marta chiqadi va yopiladi', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    expect(progress.tanishuvKurildi, isFalse);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(
      find.text('Har kuni ${Progress.kunlikMaqsad} ta savol'),
      findsOneWidget,
    );
    expect(progress.tanishuvKurildi, isTrue);

    await tester.tap(find.text('Keyingisi'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Olov va sandiq'), findsOneWidget);
    await tester.tap(find.text('Keyingisi'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Nishonlar va darajalar'), findsOneWidget);
    await tester.tap(find.text('Boshladik!'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Boshladik!'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
