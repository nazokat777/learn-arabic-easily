// Motivatsiya yadrosi: kunlik sandiq (kunda bir marta, seriya bonusi),
// olov himoyasi (sotib olish, chegara) va nishonlar (bir marta ochiladi).

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/nishonlar.dart';
import 'package:learn_arabic/progress.dart';

void main() {
  test('kunlik sandiq kunda bir marta, ball beradi', () async {
    final p = Progress();
    expect(p.sandiqOchilganBugun, isFalse);
    final natija = await p.sandiqniOch(Random(1));
    expect(natija, isNotNull);
    final (ball, _) = natija!;
    expect(ball, greaterThanOrEqualTo(5));
    expect(p.xp, ball);
    expect(p.bugungiBall, ball);
    expect(p.sandiqSoni, 1);
    expect(p.sandiqOchilganBugun, isTrue);
    // Ikkinchi marta — yo'q.
    expect(await p.sandiqniOch(Random(2)), isNull);
    expect(p.sandiqSoni, 1);
  });

  test('sandiq sovg\'asi seriya bilan o\'sadi', () async {
    // Bir xil urug': faqat seriya farq qiladi.
    final a = Progress();
    final b = Progress()..streak = 12;
    final (ba, _) = (await a.sandiqniOch(Random(7)))!;
    final (bb, _) = (await b.sandiqniOch(Random(7)))!;
    expect(bb - ba, 12);
  });

  test('olov himoyasi: 50 ballga, ko\'pi bilan 3 ta', () async {
    final p = Progress();
    expect(await p.muzlatishSotibOl(), isFalse); // ball yo'q
    await p.addXp(200);
    expect(await p.muzlatishSotibOl(), isTrue);
    expect(p.muzlatish, 1);
    expect(p.xp, 150);
    expect(await p.muzlatishSotibOl(), isTrue);
    expect(await p.muzlatishSotibOl(), isTrue);
    expect(p.muzlatish, 3);
    expect(await p.muzlatishSotibOl(), isFalse); // chegara
    expect(p.xp, 50);
  });

  test('nishonlar shart bajarilganda bir marta ochiladi', () async {
    final p = Progress();
    expect(await p.yangiNishonlar(), isEmpty);
    await p.bumpWord('n::1', true);
    final yangi = await p.yangiNishonlar();
    expect(yangi, contains('birinchi-qadam'));
    expect(p.nishonOlinganmi('birinchi-qadam'), isTrue);
    expect(p.nishonSanasi('birinchi-qadam'), isNotNull);
    // Qayta tekshirilsa — yana chiqmaydi.
    expect(await p.yangiNishonlar(), isEmpty);
    expect(p.nishonSoni, 1);
    // Katalogdagi id'lar takrorlanmaydi va topiladi.
    final idlar = nishonlar.map((n) => n.id).toList();
    expect(idlar.toSet().length, idlar.length);
    expect(nishonTop('kombo-10'), isNotNull);
    expect(nishonTop('yoq'), isNull);
  });

  test('kombo va daraja nishonlari', () async {
    final p = Progress();
    await p.rekordniYangila(12);
    await p.addXp(250); // 3-daraja
    final yangi = await p.yangiNishonlar();
    expect(yangi, containsAll(['kombo-10', 'daraja-3']));
    expect(yangi, isNot(contains('kombo-25')));
  });
}
