// Tasnif (turkum) savollari — faqat kitob jadvalidan.
//
// Nega kerak: «qaysi kalima noqis?» savolining javobi kitobning boblar
// jadvalidagi ustun bilan bir xil bo'lishi SHART; ustun sarlavhalari
// o'zgarsa yoki taxminiy juftlik chiqsa, test yiqilsin.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/mashq/bank.dart';
import 'package:learn_arabic/mashq/element.dart';
import 'package:learn_arabic/mashq/sessiya.dart';
import 'package:learn_arabic/progress.dart';

void main() {
  progress = Progress();
  final raw = File('assets/content/sarf_lessons.json').readAsStringSync();
  final darslar = (json.decode(raw)['lessons'] as List)
      .map((e) => SarfLesson.fromJson(e as Map<String, dynamic>))
      .toList();
  repo = ContentRepository()..sarfLessons = darslar;

  test('boblar jadvali (3-dars): har katak o\'z ustuniga', () {
    final dars = darslar.firstWhere((l) => l.num == 3);
    final jadval = dars.blocks.firstWhere((b) => b.type == 'jadval');
    // Kitobdagi ustun sarlavhalari aynan shu tartibda — bob nomlari
    // IV–X darslar sarlavhalari bilan mos (Sahih … Multaviy).
    expect(jadval.ustunlar.map((u) => u.ar.trim()).toList(), [
      'السَّالِمُ',
      'الْمُضَعَّفُ',
      'الْمُعْتَلُّ الفَاء',
      'الْمُعْتَلُّ العَيْنُ',
      'الْمُعْتَلّ اللاَّم',
      'اللَّفِيفُ الْمَقْرُونُ',
      'الْمَفْرُوق اللَّفِيفُ',
    ]);
    final juft = {for (final (a, u) in MashqBank.turkumJadvali(jadval)) a: u};
    expect(juft['رَعَى'], startsWith('Noqis'));
    expect(juft['رَمَى'], startsWith('Noqis'));
    expect(juft['وَثَبَ'], startsWith('Misol'));
    expect(juft['بَاعَ'], startsWith('Ajvaf'));
    expect(juft['فَرَّ'], startsWith("Muzo'af"));
    expect(juft['ضَرَبَ'], startsWith('Sahih')); // «ضَرَبَ – يَضْرِبُ» → moziy
    expect(juft['رَوَى'], startsWith('Lafif'));
    expect(juft['وَحَى'], startsWith('Multaviy'));
    expect(juft.containsKey('———'), isFalse);
    expect(juft.values.any((v) => v.contains('———')), isFalse);
    // Jadvalda 100 dan ortiq to'ldirilgan katak bor.
    expect(juft.length, greaterThan(100));
  });

  test('shakllar jadvali (36-dars): katak ↔ shakl nomi, ziddiyatsiz', () {
    final dars = darslar.firstWhere((l) => l.num == 36);
    // sarfDars dars ichidagi hamma jadvalni birga ko'radi: bir shakl ikki
    // turda bo'lsa («لا تَضْرِبْنَ» nafiy ham, nahiy ham) — tashlanadi.
    final e = MashqBank.sarfDars(dars).where((x) => x.turkum).toList();
    final hammasi = {for (final x in e) x.ar: x.uz};
    expect(hammasi.containsKey('لا تَضْرِبْنَ'), isFalse);
    expect(e.every((x) => x.guruh == 'sarf-36'), isTrue);
    expect(hammasi['ضَارِبٌ'], 'Ismi foil');
    expect(hammasi['مَضْرُوبٌ'], "Ismi maf'ul");
    expect(hammasi['مِضْرَابٌ'], 'Ismi olat');
    expect(hammasi['اِضْرِبْ'], 'Amri hozir');
    expect(hammasi.length, greaterThan(60));
  });

  test('sarfDars tasnif elementlarini turkum bilan beradi', () {
    final e = MashqBank.sarfDars(darslar.firstWhere((l) => l.num == 3));
    final turkumlar = e.where((x) => x.turkum).toList();
    expect(turkumlar.length, greaterThan(100));
    expect(turkumlar.every((x) => x.ovoz.isEmpty), isTrue);
    expect(turkumlar.every((x) => !MashqSessiya.yozibBoladi(x)), isTrue);
  });

  test(
    'teskari savolda bir xil turdagi ikkinchi kalima variant bo\'lmaydi',
    () {
      final havza = <MashqElement>[
        for (final (i, (a, u)) in const [
          ('رَعَى', 'Noqis'),
          ('رَمَى', 'Noqis'),
          ('دَعَى', 'Noqis'),
          ('بَاعَ', 'Ajvaf'),
          ('فَرَّ', "Muzo'af"),
          ('وَثَبَ', 'Misol'),
          ('ضَرَبَ', 'Sahih'),
        ].indexed)
          MashqElement(
            kalit: 't::$i',
            ar: a,
            uz: u,
            darsId: 't',
            tartib: 1,
            modul: 'Sarf',
            ovoz: '',
            turkum: true,
          ),
      ];
      // Boshqa guruh (masalan 8-dars «yَرْمِي ↔ muzore'») chalg'ituvchi
      // bo'lmaydi — u ham noqis, ikkinchi to'g'ri javob bo'lardi.
      havza.add(
        const MashqElement(
          kalit: 'sarf::8::يَرْمِي',
          ar: 'يَرْمِي',
          uz: "muzore' (رَمَى)",
          darsId: 'sarf-8',
          tartib: 8,
          modul: 'Sarf',
        ),
      );
      final y = SavolYasagich(Random(5));
      for (var k = 0; k < 30; k++) {
        final s = y.yasa(havza.first, havza, tur: MashqTuri.arabchaTop)!;
        // Faqat bitta to'g'ri javob: boshqa noqis so'zlar variantda yo'q.
        expect(s.variantlar.contains('رَمَى'), isFalse);
        expect(s.variantlar.contains('دَعَى'), isFalse);
        expect(s.variantlar.contains('يَرْمِي'), isFalse);
        expect(s.variantlar[s.togri], 'رَعَى');
      }
    },
  );

  test("vazn jadvali (o'zbekcha ma'no ustuni bor) tasnif emas", () {
    for (final n in [39, 69, 90, 93, 101, 102]) {
      final dars = darslar.firstWhere((l) => l.num == n);
      for (final b in dars.blocks.where((b) => b.type == 'jadval')) {
        expect(MashqBank.turkumJadvali(b), isEmpty, reason: '$n-dars');
      }
    }
  });
}
