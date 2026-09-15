// Ovoz qamrovi: ilova o'qib beradigan HAR BIR matn uchun klip bormi.
// Qurilma TTS ishonchsiz (arabcha ovoz yo'q / noto'g'ri o'qiydi), shuning
// uchun mashq/kartochka/gap/tasnif/harf — hammasi klipli bo'lishi shart.
// Yetishmayotganlar build/ovoz_yetishmaydi.txt ga yoziladi (generator uchun).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/arabic.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/mashq/bank.dart';
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/tarjima_mashqi.dart';

void main() {
  progress = Progress();
  final r = ContentRepository();
  List<T> oqi<T>(String f, T Function(Map<String, dynamic>) k) =>
      (json.decode(File('assets/content/$f').readAsStringSync())['lessons']
              as List)
          .map((e) => k(e as Map<String, dynamic>))
          .toList();
  r.qiroatLessons = oqi('qiroat_lessons.json', QiroatLesson.fromJson);
  r.nahvLessons = oqi('nahv_lessons.json', NahvLesson.fromJson);
  r.sarfLessons = oqi('sarf_lessons.json', SarfLesson.fromJson);
  final letters =
      (json.decode(File('assets/content/letters.json').readAsStringSync())
          as Map);
  r.letters = ((letters['letters'] ?? letters) as List)
      .map((e) => Letter.fromJson(e as Map<String, dynamic>))
      .toList();
  repo = r;

  final klip = <String>{};
  for (final m in [
    'vocab',
    'sentence',
    'word',
    'alifbo',
    'extra',
    'sarf',
    'mashq',
    'harf',
  ]) {
    final f = File('assets/audio/${m}_manifest.json');
    if (!f.existsSync()) continue;
    klip.addAll((json.decode(f.readAsStringSync()) as Map).keys.cast<String>());
  }

  test('ovoz kerak bo\'lgan har matn uchun klip bor', () {
    final kerak = <String, String>{}; // matn → manba
    void q(String matn, String manba) {
      // Tts.speak kabi: lotin qavs o'qilmaydi.
      final t = matn
          .replaceAll(RegExp(r'\s*\([^)]*[A-Za-z][^)]*\)'), '')
          // «قُعُودٌ = جَلَسَ» — «=» o'qilmasin, ikki so'z orasida pauza.
          .replaceAll(RegExp(r'\s*=\s*'), '، ')
          .trim();
      if (t.isEmpty) return;
      kerak.putIfAbsent(t, () => manba);
    }

    for (final e in MashqBank.hammasi()) {
      q(e.ovoz, 'mashq ${e.modul}');
    }
    for (final e in MashqBank.tasniflar()) {
      q(e.ovoz, 'tasnif ${e.modul}');
    }
    for (final l in r.qiroatLessons) {
      for (final v in l.vocab) {
        // So'z kartasi: bosh shakl va har grammatik shakl alohida o'qiladi.
        for (final f in splitForms(v.ar)) {
          q(f, 'lugat qiroat ${l.book}-${l.num}');
        }
        for (final sh in v.plShakllari) {
          q(sh, 'koplik qiroat ${l.book}-${l.num}');
        }
      }
      final (_, _, ar) = TarjimaMashqi.ajrat(l);
      for (final s in ar ?? TarjimaMashqi.jumlalar(l.exerciseAnswer)) {
        q(s, 'gap qiroat ${l.book}-${l.num}');
      }
      // Butun javob endi jumla-jumla o'qiladi — alohida klip kerak emas.
    }
    for (final l in r.nahvLessons) {
      for (final p in l.exercise) {
        q(p.ar, 'gap nahv ${l.book}-${l.num}');
      }
    }
    for (final h in r.letters) {
      q(h.nameAr, 'harf nomi');
    }

    final yoq = [
      for (final e in kerak.entries)
        if (!klip.contains(e.key)) e,
    ];
    File(
      'build/ovoz_yetishmaydi.txt',
    ).writeAsStringSync(yoq.map((e) => '${e.value}\t${e.key}').join('\n'));
    // ignore: avoid_print
    print('ovoz kerak: ${kerak.length}, yetishmaydi: ${yoq.length}');
    expect(yoq, isEmpty, reason: 'build/ovoz_yetishmaydi.txt ga qarang');
  });
}
