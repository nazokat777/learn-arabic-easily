// Sarf ekranlari haqiqiy kontent bilan chizilishi tekshiriladi.
//
// Nega kerak: kontentga yangi blok turi (jadval) qo'shilganda ekran
// chizishda yiqilishi mumkin, buni faqat ilovani ochib ko'rish orqali
// bilib olardik. Bu test har bir sarf darsini chindan chizadi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/sarf_home.dart';

void main() {
  progress = Progress();

  final raw = File('assets/content/sarf_lessons.json').readAsStringSync();
  final darslar = (json.decode(raw)['lessons'] as List)
      .map((e) => SarfLesson.fromJson(e as Map<String, dynamic>))
      .toList();

  // `repo` — main.dart dagi `late final` global; testda bir marta beriladi.
  repo = ContentRepository()..sarfLessons = darslar;

  test('darslar o\'qildi va raqamlari takrorlanmaydi', () {
    expect(darslar, isNotEmpty);
    final raqamlar = darslar.map((l) => l.num).toList();
    expect(raqamlar.toSet().length, raqamlar.length);
  });

  testWidgets('darslar ro\'yxati chiziladi', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SarfHome()));
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
    expect(find.text(darslar.first.title), findsOneWidget);
  });

  testWidgets('har bir dars sahifasi chiziladi', (tester) async {
    // Uzun sahifa qirqilib ketmasin — baland ekran beramiz.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final l in darslar) {
      await tester.pumpWidget(
        MaterialApp(home: SarfLessonScreen(lesson: l)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.takeException(),
        isNull,
        reason: '${l.num}-dars («${l.title}») chizilmadi',
      );
    }
  });
}
