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
}
