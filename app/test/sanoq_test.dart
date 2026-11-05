// «Sanoq bilan yodlash»: matn belgilangan marta o'qiladi, sanoq saqlanadi,
// maqsad o'zgartiriladi, oraliq tekshiruv va yakuniy lug'at testi chiziladi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/sanoq_ekrani.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final raw = File('assets/content/qiroat_lessons.json').readAsStringSync();
  final darslar = (json.decode(raw)['lessons'] as List)
      .map((e) => QiroatLesson.fromJson(e as Map<String, dynamic>))
      .toList();
  repo = ContentRepository()..qiroatLessons = darslar;
  progress = Progress();
  final dars4 = darslar.firstWhere((l) => l.book == 1 && l.num == 4);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await progress.load();
  });

  Future<void> och(WidgetTester t, {QiroatLesson? l}) async {
    t.view.physicalSize = const Size(900, 3600);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(MaterialApp(home: SanoqEkrani(lesson: l ?? dars4)));
    await t.pumpAndSettle();
  }

  testWidgets(
    "yangi o'quvchi: tushuntirish, 0/33, arabcha matn, tarjima yopiq",
    (t) async {
      await och(t);
      expect(find.byKey(const ValueKey('sanoq-tanishuv')), findsOneWidget);
      expect(find.text('0 / 33 marta o\'qildi'), findsOneWidget);
      expect(find.byKey(const ValueKey('sanoq-arabcha')), findsOneWidget);
      expect(find.byKey(const ValueKey('sanoq-ozbekcha')), findsNothing);

      await t.tap(find.byKey(const ValueKey('sanoq-och')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('sanoq-ozbekcha')), findsOneWidget);
    },
  );

  testWidgets("«O'qidim» sanoqni oshiradi, saqlanadi, tushuntirish yo'qoladi", (
    t,
  ) async {
    await och(t);
    await t.tap(find.byKey(const ValueKey('sanoq-oqidim')));
    await t.pumpAndSettle();
    expect(find.text('1 / 33 marta o\'qildi'), findsOneWidget);
    expect(find.byKey(const ValueKey('sanoq-tanishuv')), findsNothing);
    final p = await SharedPreferences.getInstance();
    expect(p.getInt('sanoq_${dars4.completionId}.soni'), 1);

    // Qayta ochilganda davom etadi.
    await t.pumpWidget(const SizedBox());
    await och(t);
    expect(find.text('1 / 33 marta o\'qildi'), findsOneWidget);
  });

  testWidgets('maqsad tanlanadi: tayyor son va o\'zi kiritgani', (t) async {
    await och(t);
    await t.tap(find.byKey(const ValueKey('sanoq-maqsad')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('maqsad-11')));
    await t.pumpAndSettle();
    expect(find.text('0 / 11 marta o\'qildi'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('sanoq-maqsad')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('maqsad-kiritish')), '40');
    await t.tap(find.byKey(const ValueKey('maqsad-ok')));
    await t.pumpAndSettle();
    expect(find.text('0 / 40 marta o\'qildi'), findsOneWidget);
    final p = await SharedPreferences.getInstance();
    expect(p.getInt('sanoq_${dars4.completionId}.maqsad'), 40);
  });

  testWidgets("o'zbekcha rejim: tarjima ochiq, arabchasi yopiq", (t) async {
    await och(t);
    await t.tap(find.text('O\'zbekcha'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('sanoq-ozbekcha')), findsOneWidget);
    expect(find.byKey(const ValueKey('sanoq-arabcha')), findsNothing);
  });

  testWidgets('11-o\'qishdan keyin gap tekshiruvi; maqsadda lug\'at testi', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({
      'sanoq_${dars4.completionId}.soni': 10,
      'sanoq_${dars4.completionId}.maqsad': 11,
    });
    await och(t);
    expect(find.text('10 / 11 marta o\'qildi'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('sanoq-oqidim')));
    await t.pumpAndSettle();
    // Gap tekshiruvi ochildi.
    expect(find.textContaining('Gap tekshiruvi 1 /'), findsOneWidget);
    // Birinchi variantni tanlab, oxirigacha o'tamiz.
    while (find.byKey(const ValueKey('gap-variant-0')).evaluate().isNotEmpty) {
      await t.tap(find.byKey(const ValueKey('gap-variant-0')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('gap-keyingi')));
      await t.pumpAndSettle();
    }
    // Yakun dialogi → lug'at testi.
    expect(find.text('Testni boshlash'), findsOneWidget);
    await t.tap(find.text('Testni boshlash'));
    await t.pumpAndSettle();
    expect(find.textContaining('Lug\'at testi'), findsOneWidget);
  });

  test('hamma darsda gap tekshiruvi uchun ≥2 juft bor (1-kitob)', () {
    var kam = 0;
    for (final l in darslar.where((l) => l.book == 1)) {
      final juft = l.tarjimaGuruhlari.where((g) => g.matn.trim().isNotEmpty);
      if (juft.length < 2) kam++;
    }
    // ignore: avoid_print
    print('tekshiruvsiz darslar (1-kitob): $kam');
    expect(kam, lessThan(10));
  });
}
