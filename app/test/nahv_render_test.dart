// Nahv darsi ekrani haqiqiy kontent bilan chiziladi va «Tarjimasiz o'qib
// sinayman» rejimi tekshiriladi: tarjimalar yopiladi, bosilgani ochiladi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/nahv_home.dart';

void main() {
  progress = Progress();

  final raw = File('assets/content/nahv_lessons.json').readAsStringSync();
  final darslar = (json.decode(raw)['lessons'] as List)
      .map((e) => NahvLesson.fromJson(e as Map<String, dynamic>))
      .toList();
  repo = ContentRepository()..nahvLessons = darslar;

  testWidgets(
    "tarjimasiz o'qib sinayman: tarjimalar yopiladi, bosilsa ochiladi",
    (tester) async {
      tester.view.physicalSize = const Size(900, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dars = darslar.first;
      final juftlar = <NahvPair>[
        for (final b in dars.blocks) ...[
          if (b.type == 'list' && (b.intro?.ar.isNotEmpty ?? false)) b.intro!,
          if (b.type != 'list') b.main!,
          if (b.type == 'list') ...b.items,
        ],
        ...dars.exercise,
      ];
      expect(juftlar.length, greaterThanOrEqualTo(2));

      await tester.pumpWidget(
        MaterialApp(home: NahvLessonScreen(lesson: dars)),
      );
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
      expect(find.text(juftlar.first.uz), findsWidgets);
      expect(find.text("Tarjimasiz o'qib sinayman"), findsOneWidget);

      await tester.tap(find.text("Tarjimasiz o'qib sinayman"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final yopiq = find.text("Tarjimasi — avval o'zingiz, keyin bosing");
      expect(yopiq, findsNWidgets(juftlar.length));
      expect(find.text("Tarjimalarni ko'rsatish"), findsOneWidget);

      // Bittasi bosilsa — faqat o'sha ochiladi (AnimatedSwitcher: avval bo'sh
      // pump, keyin vaqt).
      await tester.tap(yopiq.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(yopiq, findsNWidgets(juftlar.length - 1));
      expect(find.text(juftlar.first.uz), findsWidgets);

      // Ko'rsatish rejimiga qaytilsa — hammasi ochiq.
      await tester.tap(find.text("Tarjimalarni ko'rsatish"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(yopiq, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
