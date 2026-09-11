import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/main.dart' as app;
import 'package:learn_arabic/progress.dart';

/// Kunlik maqsad: har javob hisobga kiradi, maqsadga yetganda mukofot
/// KUNDA BIR MARTA beriladi.
void main() {
  setUpAll(() => app.progress = Progress());

  test("maqsadga yetguncha mukofot yo'q, yetganda bir marta", () async {
    final p = app.progress;
    expect(p.bugungiSavollar, 0);
    for (var i = 0; i < Progress.kunlikMaqsad - 1; i++) {
      await p.bumpWord('kun::$i', i.isEven);
      expect(await p.kunlikMukofotniOl(), isFalse);
    }
    expect(p.kunlikMaqsadBajarildi, isFalse);
    final oldingiBall = p.xp;
    await p.bumpWord('kun::oxirgi', false); // xato javob ham hisobga kiradi
    expect(p.kunlikMaqsadBajarildi, isTrue);
    expect(await p.kunlikMukofotniOl(), isTrue);
    expect(p.xp, oldingiBall + Progress.kunlikMukofotBalli);
    // Ikkinchi marta so'ralsa — berilmaydi.
    await p.bumpWord('kun::yana', true);
    expect(await p.kunlikMukofotniOl(), isFalse);
    expect(p.xp, oldingiBall + Progress.kunlikMukofotBalli);
  });

  test("seriya faqat maqsad bajarilgan kunda oshadi", () async {
    final p = Progress();
    // Oddiy ball seriyani yoqmaydi.
    await p.addXp(5);
    expect(p.streak, 0);
    expect(p.bugunSeriyada, isFalse);
    for (var i = 0; i < Progress.kunlikMaqsad; i++) {
      await p.bumpWord('seriya::$i', true);
    }
    expect(await p.kunlikMukofotniOl(), isTrue);
    expect(p.streak, 1);
    expect(p.bugunSeriyada, isTrue);
    // O'sha kuni yana ball olsa ham seriya ikkiga chiqmaydi.
    await p.addXp(50);
    expect(p.streak, 1);
    // Haftalik ko'rinish: bugun belgilangan, kecha — yo'q.
    final bugun = DateTime.now();
    expect(p.maqsadBajarilganKun(bugun), isTrue);
    expect(
      p.maqsadBajarilganKun(bugun.subtract(const Duration(days: 1))),
      isFalse,
    );
  });
}
