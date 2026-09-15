// Sharh qatlami: har kalit mavjud darsga tegishli, to'g'ri javob indeksi
// variantlar ichida, variantlar takrorlanmaydi; ekranda savolga javob
// berilsa izoh chiqadi va ball beriladi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/widgets/aralash_matn.dart';
import 'package:learn_arabic/widgets/sharh.dart';

void main() {
  progress = Progress();
  final sh = json.decode(File('assets/content/sharh.json').readAsStringSync());
  final nahv =
      (json.decode(
                File('assets/content/nahv_lessons.json').readAsStringSync(),
              )['lessons']
              as List)
          .map((e) => NahvLesson.fromJson(e))
          .toList();
  final sarf =
      (json.decode(
                File('assets/content/sarf_lessons.json').readAsStringSync(),
              )['lessons']
              as List)
          .map((e) => SarfLesson.fromJson(e))
          .toList();
  repo = ContentRepository()
    ..nahvLessons = nahv
    ..sarfLessons = sarf
    ..sharhlar = {
      for (final e in (sh['darslar'] as Map).entries)
        '${e.key}': Sharh.fromJson(e.value as Map<String, dynamic>),
    };

  test('sharh kalitlari darslarga mos, savollar to\'g\'ri tuzilgan', () {
    final ids = {
      for (final l in nahv) 'nahv-${l.book}-${l.num}',
      for (final l in sarf) l.completionId,
    };
    expect(repo.sharhlar, isNotEmpty);
    for (final e in repo.sharhlar.entries) {
      expect(ids.contains(e.key), isTrue, reason: e.key);
      expect(e.value.sharh, isNotEmpty, reason: e.key);
      for (final q in e.value.savollar) {
        expect(q.variantlar.length, greaterThanOrEqualTo(2), reason: q.savol);
        expect(q.togri, inInclusiveRange(0, q.variantlar.length - 1));
        expect(q.variantlar.toSet().length, q.variantlar.length);
      }
    }
  });

  testWidgets('qoida savoli: javob → izoh va ball', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final oldin = progress.xp;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SharhBolimi(darsId: 'nahv-1-14'),
                QoidaSavollari(darsId: 'nahv-1-14'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Sharh — oddiy tilda'), findsOneWidget);
    expect(find.text('Qoidani tekshiring'), findsOneWidget);
    final s = repo.sharhlar['nahv-1-14']!.savollar.first;
    final variant = find.byWidgetPredicate(
      (w) => w is AralashMatn && w.matn == s.variantlar[s.togri],
    );
    await tester.ensureVisible(variant);
    await tester.pump();
    await tester.tap(variant, warnIfMissed: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(progress.xp - oldin, 2);
    expect(
      find.byWidgetPredicate(
        (w) => w is AralashMatn && w.matn.startsWith("To'g'ri."),
      ),
      findsOneWidget,
    );
  });
}
