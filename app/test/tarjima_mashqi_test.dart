// Tarjima mashqi: jumlalarga ajratish, mos kelganda har jumlaning javobi
// alohida ochiladi; mos kelmaganda javob butunligicha — noto'g'ri juftlash
// bo'lmaydi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/tarjima_mashqi.dart';

void main() {
  progress = Progress();
  final raw = File('assets/content/qiroat_lessons.json').readAsStringSync();
  final darslar = (json.decode(raw)['lessons'] as List)
      .map((e) => QiroatLesson.fromJson(e as Map<String, dynamic>))
      .toList();
  repo = ContentRepository()..qiroatLessons = darslar;

  test('jumlalarga ajratish', () {
    expect(TarjimaMashqi.jumlalar('Bu qalam. Bu nima? Daftar.'), [
      'Bu qalam.',
      'Bu nima?',
      'Daftar.',
    ]);
    expect(TarjimaMashqi.jumlalar('أَيْنَ الدَّفْتَرُ؟ هَذَا قَلَمٌ.'), [
      'أَيْنَ الدَّفْتَرُ؟',
      'هَذَا قَلَمٌ.',
    ]);
  });

  test('ko\'rsatma ajratiladi, mos kelmasa javob null', () {
    var mos = 0, nomos = 0;
    for (final l in darslar.where((l) => l.exercise.isNotEmpty)) {
      final (korsatma, uz, ar) = TarjimaMashqi.ajrat(l);
      expect(uz, isNotEmpty);
      expect(
        korsatma.toLowerCase().startsWith('quyidagi') || korsatma.isEmpty,
        isTrue,
      );
      if (ar == null) {
        nomos++;
      } else {
        mos++;
        expect(ar.length, uz.length);
      }
    }
    expect(mos, greaterThan(40));
    expect(mos + nomos, greaterThan(100));
  });

  testWidgets('mos darsda javob jumla-jumla ochiladi', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dars = darslar.firstWhere((l) => TarjimaMashqi.ajrat(l).$3 != null);
    final (_, uz, ar) = TarjimaMashqi.ajrat(dars);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: TarjimaMashqi(lesson: dars)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(uz.first), findsOneWidget);
    expect(find.text('Javob'), findsNWidgets(uz.length));
    expect(find.textContaining(ar!.first), findsNothing);
    await tester.tap(find.text('Javob').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Javob'), findsNWidgets(uz.length - 1));
    // Arabcha javob SentenceText (Text.rich) bilan chiziladi.
    expect(
      find.textContaining(ar.first.split(' ').first, findRichText: true),
      findsWidgets,
    );
    await tester.tap(find.text('Hammasini ochish'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Javob'), findsNothing);
    expect(find.text('Yashirish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mos kelmagan darsda javob butun ochiladi', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dars = darslar.firstWhere(
      (l) => l.exercise.isNotEmpty && TarjimaMashqi.ajrat(l).$3 == null,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: TarjimaMashqi(lesson: dars)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Javob'), findsNothing);
    expect(find.text('Javobni ko\'rish'), findsOneWidget);
    await tester.tap(find.text('Javobni ko\'rish'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Javobni ko\'rish'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tarjima bosqichi: davom tugmasi ball beradi va oqimni davom ettiradi',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dars = darslar.firstWhere((l) => l.exercise.isNotEmpty);
      var ball = 0;
      var tugadi = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TarjimaStage(
              lesson: dars,
              award: (x) => ball += x,
              onDone: () => tugadi++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      // Juftlar mos kelgan darsda avval gap tuzish o'yini chiqadi —
      // o'tkazib yuborilsa ro'yxat va davom tugmasi.
      if (find.text('Gap tuzish').evaluate().isNotEmpty) {
        expect(find.text("O'yinni o'tkazib yuborish"), findsOneWidget);
        await tester.tap(find.text("O'yinni o'tkazib yuborish"));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text("Mashq: o'zbekchadan arabchaga"), findsOneWidget);
      await tester.tap(find.text("Savollarga o'tish"));
      await tester.pump();
      expect(ball, 5);
      expect(tugadi, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
