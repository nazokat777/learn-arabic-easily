// Nahv tasnif parseri — qat'iy qo'riqchi: kitob ro'yxatidagi misollar
// o'z turi bilan (2026-09-13 da 84 juftlik qo'lda tekshirilgan).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/mashq/bank.dart';
import 'package:learn_arabic/progress.dart';

void main() {
  progress = Progress();
  final raw = File('assets/content/nahv_lessons.json').readAsStringSync();
  final darslar = (json.decode(raw)['lessons'] as List)
      .map((e) => NahvLesson.fromJson(e as Map<String, dynamic>))
      .toList();
  repo = ContentRepository()..nahvLessons = darslar;

  NahvLesson dars(int book, int num) =>
      darslar.firstWhere((l) => l.book == book && l.num == num);

  test("ro'yxat misollari o'z turi bilan (kitob bo'yicha)", () {
    final t12 = {
      for (final x in MashqBank.nahvTurkumlar(dars(1, 2))) x.ar: x.uz,
    };
    expect(t12['كَتَبَ'], "Fe'l");
    expect(t12['اسْتَخْرِجْ'], "Fe'l");
    expect(t12['مُحَمَّدٍ'], 'Ism');
    expect(t12['قَمَرٍ'], 'Ism');
    expect(t12['هَلْ'], 'Harf');
    expect(t12['ثُمَّ'], 'Harf');
    expect(t12.length, 25);

    final t13 = {
      for (final x in MashqBank.nahvTurkumlar(dars(1, 3))) x.ar: x.uz,
    };
    expect(t13['كَتَبَ'], 'Mozi');
    expect(t13['يَكْتُبُ'], "Muzori'");
    expect(t13['اكْتُبْ'], 'Amr');

    final t14 = {
      for (final x in MashqBank.nahvTurkumlar(dars(1, 4))) x.ar: x.uz,
    };
    expect(t14['حِصَانٍ'], 'Muzakkar');
    expect(t14['نَاقَةٍ'], 'Muannas');

    final t15 = {
      for (final x in MashqBank.nahvTurkumlar(dars(1, 5))) x.ar: x.uz,
    };
    expect(t15['فَاضِلٍ'], 'Mufrad');
    expect(t15['فَاضِلَتَيْنِ'], 'Musanno');
    // «فَاضِلُونَ أَوْ فَاضِلِينَ» — bo'shliqli bo'lak: butun band tashlanadi.
    expect(t15.containsKey('فَاضِلُونَ'), isFalse);
  });

  test("hech bir juftlikda bo'shliq, qo'shtirnoq yoki oyat belgisi yo'q", () {
    var jami = 0;
    for (final l in darslar) {
      for (final x in MashqBank.nahvTurkumlar(l)) {
        jami++;
        expect(x.ar.contains(' '), isFalse, reason: x.ar);
        expect(x.ar.contains('«') || x.ar.contains('﴿'), isFalse, reason: x.ar);
        expect(x.turkum, isTrue);
        expect(x.ovoz, isEmpty);
        expect(x.guruh, startsWith('nahv-'));
      }
    }
    // Qo'lda tekshirilgan to'plam hajmi — o'zgarsa, qayta ko'rib chiqiladi.
    expect(jami, 84);
  });

  test('nahvDars tasnifni ham beradi', () {
    final e = MashqBank.nahvDars(dars(1, 2));
    expect(e.where((x) => x.turkum).length, 25);
    // Oldingi darslar havzasi ham tasnifni o'z ichiga oladi.
    expect(
      MashqBank.nahvGacha(dars(1, 3)).where((x) => x.turkum).length,
      greaterThan(25),
    );
  });
}
