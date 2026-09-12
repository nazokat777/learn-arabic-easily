// O'qish bosqichi: jumlalar chiziladi, oxirida YOPIQ tarjima kartasi —
// bosilganda kitobdagi tarjima ochiladi, yana bosilsa yopiladi.

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

  testWidgets("o'qish bosqichida tarjima yopiq, bosilsa ochiladi", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dars = darslar.first;
    expect(dars.translation, isNotEmpty);
    var tugadi = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadStage(lesson: dars, onDone: () => tugadi++, award: (_) {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);

    final yopiq = find.text(
      "Tarjimasini tekshirish — avval o'zingiz tushuning",
    );
    expect(yopiq, findsOneWidget);
    expect(find.text(dars.translation), findsNothing);

    await tester.tap(yopiq);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Tarjimasi'), findsOneWidget);
    expect(find.text(dars.translation), findsOneWidget);

    await tester.tap(find.text('Tarjimasi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(dars.translation), findsNothing);
    expect(tugadi, 0);
    expect(tester.takeException(), isNull);
  });
}
