// Sahifa manzili: `#/modul/id` ajratiladi va darsEkrani to'g'ri ekranni beradi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/davom.dart';
import 'package:learn_arabic/screens/nahv_home.dart';
import 'package:learn_arabic/screens/sarf_home.dart';
import 'package:learn_arabic/services/manzil.dart';

void main() {
  progress = Progress();
  List<T> oqi<T>(String fayl, T Function(Map<String, dynamic>) f) =>
      (json.decode(File('assets/content/$fayl').readAsStringSync())['lessons']
              as List)
          .map((e) => f(e as Map<String, dynamic>))
          .toList();
  repo = ContentRepository()
    ..nahvLessons = oqi('nahv_lessons.json', NahvLesson.fromJson)
    ..sarfLessons = oqi('sarf_lessons.json', SarfLesson.fromJson);

  test('manzil bo\'lagi ajratiladi', () {
    expect(Manzil.ajrat('/nahv/nahv-1-5'), ('nahv', 'nahv-1-5'));
    expect(Manzil.ajrat('sarf/sarf-12'), ('sarf', 'sarf-12'));
    expect(Manzil.ajrat('/alifbo/harf%20ba'), ('alifbo', 'harf ba'));
    expect(Manzil.ajrat(''), isNull);
    expect(Manzil.ajrat('/'), isNull);
    expect(Manzil.ajrat('/nahv'), isNull);
    expect(Manzil.ajrat('/boshqa/x'), isNull);
    expect(Manzil.ajrat('/nahv/a/b'), isNull);
  });

  test('darsEkrani manzildan ekran yasaydi', () {
    final n = repo.nahvLessons.first;
    expect(
      darsEkrani('nahv', 'nahv-${n.book}-${n.num}'),
      isA<NahvLessonScreen>(),
    );
    final s = repo.sarfLessons.first;
    expect(darsEkrani('sarf', s.completionId), isA<SarfLessonScreen>());
    expect(darsEkrani('nahv', 'yoq-dars'), isNull);
    expect(darsEkrani('sarf', ''), isNull);
  });
}
