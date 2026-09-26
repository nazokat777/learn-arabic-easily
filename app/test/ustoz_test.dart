import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/main.dart' as m;
import 'package:learn_arabic/ustoz/javob_dvigateli.dart';

/// Ustoz dvigateli: javob kitobdan chiqishini va turlarni to'g'ri
/// ajratishini qo'riqlaydi.
void main() {
  m.progress = Progress();
  final r = ContentRepository();
  List<T> oqi<T>(String f, T Function(Map<String, dynamic>) k) =>
      (json.decode(File('assets/content/$f').readAsStringSync())['lessons']
              as List)
          .map((e) => k(e as Map<String, dynamic>))
          .toList();
  r.qiroatLessons = oqi('qiroat_lessons.json', QiroatLesson.fromJson);
  r.nahvLessons = oqi('nahv_lessons.json', NahvLesson.fromJson);
  r.sarfLessons = oqi('sarf_lessons.json', SarfLesson.fromJson);
  r.words =
      (json.decode(
                File('assets/content/vocabulary.json').readAsStringSync(),
              )['words']
              as List)
          .map((e) => VocabWord.fromJson(e as Map<String, dynamic>))
          .toList();
  r.sharhlar = {
    for (final e
        in (json.decode(
                  File('assets/content/sharh.json').readAsStringSync(),
                )['darslar']
                as Map)
            .entries)
      '${e.key}': Sharh.fromJson(e.value as Map<String, dynamic>),
  };
  m.repo = r;

  test('o\'zbekcha jumla — kitobdagi arabchasi topiladi', () {
    final j = JavobDvigateli.instance.javob('Kitob qayerda?');
    expect(j.arabcha.isNotEmpty, true, reason: j.matn);
    // So'zma-so'z emas, KITOBDAGI jumla topilishi kerak.
    expect(j.arabcha.contains('أَيْنَ'), true, reason: 'topilgan: ${j.arabcha}');
    expect(j.arabcha.split(' ').length >= 2, true,
        reason: 'jumla emas: ${j.arabcha}');
    expect(j.matn.toLowerCase().contains('kitob'), true, reason: j.matn);
    expect(j.manbalar.isNotEmpty, true);
  });

  test('arabcha jumla — o\'zbekcha tarjimasi kitobdan', () {
    final j = JavobDvigateli.instance.javob('أَيْنَ الْكُتُبُ؟');
    expect(j.aniq, true, reason: j.matn);
    expect(j.matn.toLowerCase().contains('kitob'), true, reason: j.matn);
  });

  test('qoida savoli — Sharh/kitobdan javob va manba', () {
    final j = JavobDvigateli.instance.javob('Majhul fe\'l nima?');
    expect(j.matn.length > 30, true, reason: j.matn);
    expect(j.manbalar.isNotEmpty, true);
  });

  test('kitobda yo\'q narsa — taxminiy deb belgilanadi', () {
    final j = JavobDvigateli.instance.javob('Kompyuter dasturchisi keldi');
    expect(j.aniq, false);
  });

  test('savol turlari ajratiladi', () {
    final d = JavobDvigateli.instance;
    expect(d.turiniTop('أَيْنَ الْكِتَابُ؟'), SavolTuri.arabchaMatn);
    expect(d.turiniTop('Jazm qachon bo\'ladi?'), SavolTuri.qoidaSavoli);
    expect(d.turiniTop('Bola maktabga bordi'), SavolTuri.ozbekchaMatn);
  });
}
