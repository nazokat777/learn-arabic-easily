// Nishonlar ekrani chiziladi (ochiq va yopiq kataklar) va chaqmoq raundda
// vaqt tugaganda yakun «Vaqt tugadi!» chiqadi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/main.dart' show progress;
import 'package:learn_arabic/mashq/element.dart';
import 'package:learn_arabic/mashq/mashq_ekran.dart';
import 'package:learn_arabic/nishonlar.dart';
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/nishonlar_ekrani.dart';

MashqElement _el(String ar, String uz) => MashqElement(
  kalit: 'chaqmoq::$ar',
  ar: ar,
  uz: uz,
  darsId: 'chaqmoq-1',
  tartib: 1,
  modul: 'Sinov',
  ovoz: '',
);

void main() {
  setUpAll(() => progress = Progress());

  testWidgets('nishonlar ekrani: ochiq va yopiq kataklar', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await progress.bumpWord('nishon::a', true);
    final yangi = await progress.yangiNishonlar();
    expect(yangi, contains('birinchi-qadam'));

    await tester.pumpWidget(const MaterialApp(home: NishonlarEkrani()));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull);
    expect(find.text('1 / ${nishonlar.length} ochildi'), findsOneWidget);
    expect(find.text('Birinchi qadam'), findsOneWidget);
    // Yopiq nishonlar ham ko'rinadi — tavsifi bilan.
    expect(find.text('Kombo 10'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
  });

  testWidgets('chaqmoq raund: vaqt tugaganda yakun', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MashqEkran(
          sarlavha: 'Chaqmoq raund',
          darsniki: [
            _el('كَتَبَ', 'yozdi'),
            _el('ذَهَبَ', 'ketdi'),
            _el('سَمِعَ', 'eshitdi'),
            _el('فَتَحَ', 'ochdi'),
          ],
          oldingilar: const [],
          tezkorSoniya: 3,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('3 s'), findsOneWidget);
    // Vaqt o'tadi — soniyalar kamayadi, keyin yakun.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Vaqt tugadi!'), findsOneWidget);
    expect(find.textContaining('(2×)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Taymer to'xtagan — ekran yopilganda xato yo'q.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
