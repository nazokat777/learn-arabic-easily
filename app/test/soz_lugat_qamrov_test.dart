// Gap tuzish: so'z lug'ati kitob mashqlaridagi so'zlarning qanchasini qoplaydi.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/mashq/soz_lugat.dart';
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/lesson/gap_tuzish.dart';
import 'package:learn_arabic/screens/tarjima_mashqi.dart';

void main() {
  test("lug'at gap tuzish so'zlarining ko'pini qoplaydi", () {
    progress = Progress();
    final raw = File('assets/content/qiroat_lessons.json').readAsStringSync();
    final nraw = File('assets/content/nahv_lessons.json').readAsStringSync();
    repo = ContentRepository()
      ..qiroatLessons = [
        for (final e in json.decode(raw)['lessons'] as List)
          QiroatLesson.fromJson(e as Map<String, dynamic>),
      ]
      ..nahvLessons = [
        for (final e in json.decode(nraw)['lessons'] as List)
          NahvLesson.fromJson(e as Map<String, dynamic>),
      ];
    var jami = 0, bor = 0;
    final yoq = <String>{};
    for (final l in repo.qiroatLessons) {
      final (_, _, ar) = TarjimaMashqi.ajrat(l);
      if (ar == null) continue;
      for (final g in ar) {
        for (final w in GapTuzish.sozlar(g)) {
          jami++;
          if (SozLugat.tarjima(w) != null) {
            bor++;
          } else {
            yoq.add(w);
          }
        }
      }
    }
    File('build/soz_lugat_yoq.txt').writeAsStringSync(yoq.join('\n'));
    // ignore: avoid_print
    print('qamrov: $bor / $jami');
    expect(bor / jami, greaterThan(0.5));
  });
}
