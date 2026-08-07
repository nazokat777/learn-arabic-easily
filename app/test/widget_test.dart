// Progress (XP / daraja) mantig'ining unit testlari.
//
// Eski Flutter shablon "counter smoke test"i o'chirildi — ilovada bunday
// ekran yo'q. Buning o'rniga daraja hisoblash formulasi tekshiriladi.
// Progress.xp ochiq maydon bo'lgani uchun asset/prefs yuklashsiz test qilamiz.

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/progress.dart';

void main() {
  group('Progress daraja mantig\'i', () {
    test('0 XP → 1-daraja, 0% taraqqiyot', () {
      final p = Progress()..xp = 0;
      expect(p.level, 1);
      expect(p.xpInLevel, 0);
      expect(p.levelProgress, 0.0);
    });

    test('Har 100 XP keyingi darajaga o\'tkazadi', () {
      expect((Progress()..xp = 99).level, 1);
      expect((Progress()..xp = 100).level, 2);
      expect((Progress()..xp = 250).level, 3);
    });

    test('xpInLevel — daraja ichidagi qoldiq XP', () {
      final p = Progress()..xp = 250;
      expect(p.xpInLevel, 50);
      expect(p.levelProgress, 0.5);
    });

    test('levelName daraja bilan mos keladi va chegaradan oshmaydi', () {
      expect((Progress()..xp = 0).levelName, 'Mubtadi\'');
      // Juda katta XP oxirgi nom bilan cheklanadi (indeks xatosi bo'lmaydi).
      expect((Progress()..xp = 99999).levelName, 'Alloma');
    });
  });
}
