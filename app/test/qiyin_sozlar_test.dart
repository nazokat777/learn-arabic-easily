// «Qiyin so'zlarim»: tanlov saqlanadi, tugma soni o'zgaradi, usullar ochiladi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/lesson/qiyin_sozlar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  progress = Progress();
  final darslar =
      ((json.decode(
                    File(
                      'assets/content/qiroat_lessons.json',
                    ).readAsStringSync(),
                  )
                  as Map)['lessons']
              as List)
          .map((e) => QiroatLesson.fromJson(e as Map<String, dynamic>))
          .toList();
  repo = ContentRepository()..qiroatLessons = darslar;

  const uy = QiroatVocab(ar: 'بَيْتٌ', pl: 'بُيُوتٌ', uz: 'uy');
  final dars = QiroatLesson(
    book: 1,
    num: 98,
    titleAr: 'x',
    reading: 'هَذَا بَيْتٌ.',
    vocab: const [
      uy,
      QiroatVocab(ar: 'قَلَمٌ', pl: 'أَقْلَامٌ', uz: 'qalam'),
    ],
  );

  setUpAll(() => progress.load());

  test('tanlov qaytadan yuklanganda saqlanib qoladi', () async {
    const id = 'sinov-saqlash';
    await QiyinTanlov.almashtir(id, uy);
    expect(QiyinTanlov.bormi(id, uy), isTrue);

    final yangi = Progress();
    await yangi.load();
    expect(yangi.tanlanganMi(id, uy.ar), isTrue);
    expect(yangi.tanlanganlar(id).single['pl'], uy.pl);

    await QiyinTanlov.almashtir(id, uy);
    expect(QiyinTanlov.bormi(id, uy), isFalse);
  });

  testWidgets("belgilansa chuqur mashq va usullar chiqadi", (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: QiyinSozlarEkrani(lesson: dars)));
    expect(find.byKey(const ValueKey('qiyin-boshla')), findsNothing);

    await t.runAsync(() async {
      await t.tap(find.byKey(ValueKey('qiyin-${uy.ar}')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await t.pump();

    expect(find.byKey(const ValueKey('qiyin-boshla')), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Ayting'), findsOneWidget);
    expect(find.text('Gapda'), findsOneWidget);
    expect(find.text('Yozing'), findsOneWidget);
  });

  test(
    "gap so'zlari: hamma darsda ma'nosi bor, lug'at bilan takrorlanmaydi",
    () {
      var jami = 0;
      for (final l in darslar) {
        final ro = QiyinTanlov.gapSozlari(l);
        jami += ro.length;
        for (final v in ro) {
          expect(v.uz.trim(), isNotEmpty);
          expect(l.vocab.any((x) => x.ar == v.ar), isFalse);
        }
        expect(ro.map((v) => v.ar).toSet().length, ro.length);
      }
      expect(jami, greaterThan(0));
    },
  );
}
