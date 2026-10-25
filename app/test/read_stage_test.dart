// O'qish bosqichi: har gap kartasida YOPIQ «Tarjima» — bosilganda shu gapning
// kitobdagi tarjimasi ochiladi (faol eslash: avval o'zi tushunadi, keyin
// tekshiradi). Gapma-gap tarjima bo'lmagan darsda — oldingidek oxirida
// butun tarjimali yopiq karta.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/lesson/read_flow.dart';

void main() {
  progress = Progress();

  final raw = File('assets/content/qiroat_lessons.json').readAsStringSync();
  final darslar = (json.decode(raw)['lessons'] as List)
      .map((e) => QiroatLesson.fromJson(e as Map<String, dynamic>))
      .toList();
  repo = ContentRepository()..qiroatLessons = darslar;

  void katta(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    "o'qish bosqichida har gapning tarjimasi yopiq, bosilsa ochiladi",
    (tester) async {
      katta(tester);
      final dars = darslar.first; // 1-dars: «هذا كتاب.» = «Bu kitob.»
      expect(dars.tarjimaGuruhlari, isNotEmpty);
      var tugadi = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadStage(
              lesson: dars,
              onDone: () => tugadi++,
              award: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);

      // Butun tarjimali yopiq karta endi yo'q — tarjima har gapning o'zida.
      expect(
        find.text("Tarjimasini tekshirish — avval o'zingiz tushuning"),
        findsNothing,
      );
      expect(find.text('Bu kitob.'), findsNothing);

      final birinchi = find.byKey(const ValueKey('read-tarjima-0'));
      expect(birinchi, findsOneWidget);
      await tester.tap(birinchi);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Bu kitob.'), findsOneWidget);
      // Ochilgach tugma o'rnida tarjima turadi; boshqa gaplarniki hali yopiq.
      expect(birinchi, findsNothing);
      expect(find.text('Bu chizg\'ich.'), findsNothing);
      expect(tugadi, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("gapma-gap tarjima yo'q darsda — butun tarjimali yopiq karta", (
    tester,
  ) async {
    katta(tester);
    final b = darslar.first;
    final yalang = QiroatLesson(
      book: b.book,
      num: b.num,
      titleAr: b.titleAr,
      reading: b.reading,
      vocab: b.vocab,
      translation: b.translation,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadStage(lesson: yalang, onDone: () {}, award: (_) {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('read-tarjima-0')), findsNothing);
    final yopiq = find.text(
      "Tarjimasini tekshirish — avval o'zingiz tushuning",
    );
    expect(yopiq, findsOneWidget);
    expect(find.text(yalang.translation), findsNothing);

    await tester.tap(yopiq);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Tarjimasi'), findsOneWidget);
    expect(find.text(yalang.translation), findsOneWidget);

    await tester.tap(find.text('Tarjimasi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(yalang.translation), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("ikki gapni qamragan tarjima — izoh bilan ochiladi", (
    tester,
  ) async {
    katta(tester);
    // 2-kitob 13-dars: 13–14-gaplarning tarjimasi kitobda bitta jumlada.
    final dars = darslar.firstWhere((l) => l.book == 2 && l.num == 13);
    final guruh = dars.tarjimaGuruhlari.firstWhere((g) => g.soni == 2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadStage(lesson: dars, onDone: () {}, award: (_) {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final tugma = find.byKey(ValueKey('read-tarjima-${guruh.boshi}'));
    await tester.ensureVisible(tugma);
    await tester.tap(tugma);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text(guruh.matn),
      findsOneWidget,
    ); // ikkinchi kartada takrorlanmaydi
    expect(
      find.textContaining(
        '${guruh.boshi + 1}–${guruh.boshi + 2}-gaplarning tarjimasi',
      ),
      findsOneWidget,
    );
    // Ikkinchi gapda — faqat ishora.
    expect(
      find.text(
        'Tarjimasi ${guruh.boshi + 1}-gap bilan birga berilgan (yuqorida)',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('read-tarjima-${guruh.boshi + 1}')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
