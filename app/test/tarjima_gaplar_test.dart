// Gapma-gap tarjima: ma'lumot butunligi (hamma 169 darsda) va kartaning
// ishlashi. Kitob tarjimasi o'zgarmaydi — faqat arabcha gaplarga bo'lingan.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/arabic.dart' show splitSentences;
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/gapma_gap_tarjima.dart';

void main() {
  progress = Progress();
  final raw = File('assets/content/qiroat_lessons.json').readAsStringSync();
  final darslar = (json.decode(raw)['lessons'] as List)
      .map((e) => QiroatLesson.fromJson(e as Map<String, dynamic>))
      .toList();
  repo = ContentRepository()..qiroatLessons = darslar;

  String norm(String s) => s.replaceAll(RegExp(r'\s+'), '');

  test("har darsda tarjima guruhlari arabcha gaplarni uzluksiz qoplaydi", () {
    expect(darslar.length, 169);
    for (final l in darslar) {
      final n = splitSentences(l.reading).length;
      expect(l.tarjimaGuruhlari, isNotEmpty, reason: l.completionId);
      var boshi = 0;
      for (final g in l.tarjimaGuruhlari) {
        expect(g.boshi, boshi, reason: l.completionId);
        expect(g.soni, greaterThanOrEqualTo(1), reason: l.completionId);
        boshi += g.soni;
      }
      expect(boshi, n, reason: '${l.completionId}: ${l.reading}');
    }
  });

  test(
    "sarlavha + guruh matnlari = kitobdagi tarjima (ilova qo'shganlarsiz)",
    () {
      for (final l in darslar) {
        final kitobdan = [
          if (l.tarjimaSarlavha.isNotEmpty) l.tarjimaSarlavha,
          for (final g in l.tarjimaGuruhlari)
            if (!g.qoshimcha) g.matn,
        ].join(' ');
        expect(norm(kitobdan), norm(l.translation), reason: l.completionId);
      }
    },
  );

  test("ilova qo'shgan tarjima — faqat bitta gapli, matni bor, 28 ta", () {
    var jami = 0;
    for (final l in darslar) {
      for (final g in l.tarjimaGuruhlari.where((g) => g.qoshimcha)) {
        jami++;
        expect(g.soni, 1, reason: l.completionId);
        expect(g.matn.trim(), isNotEmpty, reason: l.completionId);
      }
    }
    expect(jami, 28);
  });

  test("tarjimasiz guruh — faqat she'r muallifi nomi (qavs ichida)", () {
    var jami = 0;
    for (final l in darslar) {
      final gaplar = splitSentences(l.reading);
      for (final g in l.tarjimaGuruhlari.where(
        (g) => g.matn.isEmpty && !g.qoshimcha,
      )) {
        jami++;
        final matn = gaplar.sublist(g.boshi, g.boshi + g.soni).join(' ');
        expect(matn.trim().startsWith('('), isTrue, reason: l.completionId);
        expect(matn.trim().endsWith(')'), isTrue, reason: l.completionId);
      }
    }
    expect(jami, 4);
  });

  test("sarlavha faqat 2- va 3-kitobda; she'rda bayt satrlari qatorlangan", () {
    for (final l in darslar.where((l) => l.book == 1)) {
      expect(l.tarjimaSarlavha, isEmpty, reason: l.completionId);
    }
    final sher = darslar.firstWhere((l) => l.book == 3 && l.num == 21);
    expect(sher.tarjimaSarlavha, 'Hikmatli qasida');
    expect(sher.tarjimaGuruhlari.first.matn, contains('\n'));
  });

  testWidgets("karta: tarjimalar yopiq, «Tarjima» ochadi, «Hammasini ochish»", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 12000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1-kitob 47-dars: 15 gap kitob tarjimasi, 9 gap — ilova qo'shgan.
    final dars = darslar.firstWhere((l) => l.book == 1 && l.num == 47);
    final birinchi = dars.tarjimaGuruhlari.first;
    final qoshgan = dars.tarjimaGuruhlari.firstWhere((g) => g.qoshimcha);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: GapmaGapTarjima(lesson: dars)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    expect(find.text('Tarjima — gapma-gap'), findsOneWidget);
    expect(find.text(birinchi.matn), findsNothing);
    expect(find.text(qoshgan.matn), findsNothing);

    await tester.tap(find.byKey(const ValueKey('gg-tarjima-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(birinchi.matn), findsOneWidget);
    expect(find.text(qoshgan.matn), findsNothing);

    await tester.tap(find.text('Hammasini ochish'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(qoshgan.matn), findsOneWidget);
    expect(find.textContaining("Ilova qo'shgan tarjima"), findsWidgets);
    expect(find.text('Yashirish'), findsOneWidget);

    await tester.tap(find.text('Yashirish'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(birinchi.matn), findsNothing);
    expect(find.text('Hammasini ochish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("karta: sarlavha va ikki gapli qator", (tester) async {
    tester.view.physicalSize = const Size(900, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dars = darslar.firstWhere((l) => l.book == 2 && l.num == 13);
    final ikki = dars.tarjimaGuruhlari.firstWhere((g) => g.soni == 2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: GapmaGapTarjima(lesson: dars)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Ikki gapli qator raqami «13–14.»
    expect(find.text('${ikki.boshi + 1}–${ikki.boshi + 2}.'), findsOneWidget);

    expect(find.text(dars.tarjimaSarlavha), findsNothing);
    await tester.tap(find.byKey(const ValueKey('gg-sarlavha')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(dars.tarjimaSarlavha), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
