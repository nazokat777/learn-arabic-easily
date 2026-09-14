// Harf chizish: chizilsa «Yozdim!» bo'ladi, keyingi harfga o'tadi, har 5
// harfda ball; «Tozalash» chiziqni o'chiradi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/harf_chizish.dart';

Letter _h(int id, String ar, String nom) => Letter(
  id: id,
  ar: ar,
  nameUz: nom,
  nameAr: ar,
  translit: nom.toLowerCase(),
  makhrajUz: '',
  connectsLeft: true,
);

void main() {
  setUpAll(() => progress = Progress());

  testWidgets('chizish, tozalash, keyingi va ball', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final harflar = [for (var i = 1; i <= 6; i++) _h(i, 'ب', 'Harf $i')];
    await tester.pumpWidget(
      MaterialApp(home: HarfChizishEkrani(harflar: harflar)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 / 6'), findsOneWidget);
    expect(find.text('Keyingi'), findsOneWidget);
    expect(find.text('Shu yerga yozing'), findsOneWidget);

    // Chizish — tugma «Yozdim!» ga aylanadi, ko'rsatma yo'qoladi.
    final tuval = find.text('Shu yerga yozing');
    final markaz = tester.getCenter(tuval);
    await tester.dragFrom(markaz - const Offset(0, 120), const Offset(60, -40));
    await tester.pump();
    expect(find.text('Yozdim!'), findsOneWidget);
    expect(find.text('Shu yerga yozing'), findsNothing);

    // Tozalash — bo'sh holatga qaytadi.
    await tester.tap(find.text('Tozalash'));
    await tester.pump();
    expect(find.text('Keyingi'), findsOneWidget);

    // 5 ta harfni chizib o'tsak — +3 ball.
    final oldin = progress.xp;
    for (var i = 0; i < 5; i++) {
      final m = tester.getCenter(find.text('Shu yerga yozing'));
      await tester.dragFrom(m - const Offset(0, 120), const Offset(40, -30));
      await tester.pump();
      await tester.tap(find.text('Yozdim!'));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('6 / 6'), findsOneWidget);
    expect(progress.xp, oldin + 3);
    expect(find.text('Bugun yozildi: 5 ta harf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("boshlang'ich harf: dars oynasidan kelganda o'sha harf", (
    tester,
  ) async {
    final harflar = [for (var i = 1; i <= 6; i++) _h(i, 'ب', 'Harf $i')];
    await tester.pumpWidget(
      MaterialApp(home: HarfChizishEkrani(harflar: harflar, boshlanish: 3)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('4 / 6'), findsOneWidget);
    expect(find.textContaining('Harf 4'), findsOneWidget);
  });
}
