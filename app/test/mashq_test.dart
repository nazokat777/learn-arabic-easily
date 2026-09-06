import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/main.dart' as app;
import 'package:learn_arabic/mashq/element.dart';
import 'package:learn_arabic/mashq/sessiya.dart';
import 'package:learn_arabic/progress.dart';

/// Mashq mexanizmi — «bilmasdan o'tib ketish» mumkin emasligini
/// qo'riqlaydigan testlar. Bu yerdagi xato eng qimmatga tushadi:
/// o'quvchi o'zlashtirmagan darsni o'zlashtirgan deb o'ylab ketaveradi.
void main() {
  setUpAll(() {
    // Elementlarning «zaiflik» hisobi global `progress` ga tayanadi.
    app.progress = Progress();
  });

  MashqElement el(String ar, String uz, {int tartib = 1}) => MashqElement(
    kalit: 'test::$ar',
    ar: ar,
    uz: uz,
    darsId: 'test-1',
    tartib: tartib,
    modul: 'Test',
  );

  final beshta = [
    el('كِتَاب', 'kitob'),
    el('قَلَم', 'qalam'),
    el('بَاب', 'eshik'),
    el('بَيْت', 'uy'),
    el('مَاء', 'suv'),
  ];

  MashqSessiya sessiya({List<MashqElement>? dars, List<MashqElement>? oldin}) =>
      MashqSessiya(
        darsniki: dars ?? beshta,
        oldingilar: oldin ?? beshta,
        rnd: Random(7),
      );

  group('Navbat', () {
    test('xato javob elementni navbatdan chiqarmaydi', () {
      final n = BosqichNavbati([...beshta]);
      final birinchi = n.joriy!;
      n.javob(false, Random(1));
      // Element yana navbatda bo'lishi shart.
      final qolgan = <String>{};
      while (!n.bosh) {
        qolgan.add(n.joriy!.kalit);
        n.javob(true, Random(1));
      }
      expect(qolgan, contains(birinchi.kalit));
    });

    test("to'g'ri javob elementni chiqaradi", () {
      final n = BosqichNavbati([...beshta]);
      final oldin = n.qolgan;
      n.javob(true, Random(1));
      expect(n.qolgan, oldin - 1);
    });

    test('xato bo\'lgan tur «toza» hisoblanmaydi', () {
      final n = BosqichNavbati([...beshta]);
      n.javob(false, Random(1));
      expect(n.tozaOtdi, isFalse);
      expect(n.xatolar, isNotEmpty);
    });
  });

  group('Sessiya bosqichlari', () {
    test('xatosiz o\'tilsa: dars → takror → yozish → tugadi', () {
      final s = sessiya();
      expect(s.bosqich, Bosqich.dars);

      // Dars bosqichini xatosiz yakunlaymiz.
      while (s.bosqich == Bosqich.dars) {
        s.javobBer(true, birinchiUrinish: true);
      }
      expect(s.bosqich, Bosqich.takror);

      while (s.bosqich == Bosqich.takror) {
        s.javobBer(true, birinchiUrinish: true);
      }
      expect(s.bosqich, Bosqich.yozish);

      while (s.bosqich == Bosqich.yozish) {
        s.javobBer(true, birinchiUrinish: true);
      }
      expect(s.bosqich, Bosqich.tugadi);
      expect(s.foiz, 100);
    });

    test('xato qilinsa bosqich tugamaydi — xatolar qaytariladi', () {
      final s = sessiya();
      // Birinchi savolga xato, qolganiga to'g'ri javob beramiz.
      s.javobBer(false, birinchiUrinish: true);
      var qadam = 0;
      while (s.bosqich == Bosqich.dars && qadam < 50) {
        s.javobBer(true, birinchiUrinish: false);
        qadam++;
      }
      // Bitta xato uchun kamida bitta qo'shimcha savol so'ralgan bo'lishi
      // kerak: 5 element + xatoni qaytarish + xatolar turi.
      expect(s.jamiSoralgan, greaterThan(beshta.length));
      expect(s.foiz, lessThan(100));
    });
  });

  group('Zaif elementlarni tanlash', () {
    test('xato qilingan element ko\'proq chiqadi', () {
      final s = sessiya();
      // Sun'iy ravishda bitta elementni «qiyin» qilamiz.
      final qiyin = beshta[2];
      app.progress.bumpWord(qiyin.kalit, false);
      app.progress.bumpWord(qiyin.kalit, false);
      app.progress.bumpWord(qiyin.kalit, false);

      var uchradi = 0;
      for (var i = 0; i < 200; i++) {
        final tanlangan = s.zaiflarniTanla(beshta, 2);
        if (tanlangan.any((e) => e.kalit == qiyin.kalit)) uchradi++;
      }
      // 5 elementdan 2 tasi tasodifan tanlansa ~40% kutiladi; xatolar
      // og'irligi bilan sezilarli ko'proq chiqishi shart.
      expect(uchradi, greaterThan(100));
    });

    test('so\'ralgan sondan ko\'p element qaytmaydi', () {
      final s = sessiya();
      expect(s.zaiflarniTanla(beshta, 3).length, 3);
      expect(s.zaiflarniTanla(beshta, 99).length, beshta.length);
    });
  });

  group('Harflab yozish', () {
    test('qisqa bir so\'zli element yoziladi, uzun jumla — yo\'q', () {
      expect(MashqSessiya.yozibBoladi(el('كِتَاب', 'kitob')), isTrue);
      expect(
        MashqSessiya.yozibBoladi(el('الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', 'hamd')),
        isFalse,
      );
    });

    test('harflarga: harakatlar tashlanadi', () {
      expect(harflarga('كِتَاب').join(), 'كتاب');
      expect(harflarga('بَـيْـت').join(), 'بيت');
    });
  });

  group('Savol yasash', () {
    test('chalg\'ituvchi yetmasa savol yasalmaydi', () {
      final y = SavolYasagich(Random(3));
      final ikkita = beshta.take(2).toList();
      expect(y.yasa(ikkita.first, ikkita, tur: MashqTuri.manoTop), isNull);
    });

    test('to\'g\'ri javob variantlar ichida va bitta', () {
      final y = SavolYasagich(Random(5));
      final s = y.yasa(beshta.first, beshta, tur: MashqTuri.manoTop)!;
      expect(s.variantlar.length, 4);
      expect(s.variantlar[s.togri], beshta.first.uz);
      expect(s.variantlar.toSet().length, 4, reason: 'variant takrorlanmasin');
    });
  });
}
