import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' as m;
import 'package:learn_arabic/mnemonika/reja.dart';
import 'package:learn_arabic/mnemonika/xarita.dart';
import 'package:learn_arabic/progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mnemonika rejasi: xarita sonlari kontentga mos, kunlarga bo'lish
/// hech bir so'z/darsni tashlab ketmaydi va takrorlamaydi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
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
  m.repo = r;

  test('xarita: kitoblar va sonlar kontentdan', () {
    final k = KitobXarita.hammasi();
    expect(k.map((x) => x.id).toList(), [
      'qiroat-1', 'qiroat-2', 'qiroat-3',
      'nahv-1', 'nahv-2', 'nahv-3', 'nahv-4', 'sarf',
    ]);
    final q1 = KitobXarita.top('qiroat-1')!;
    expect(q1.darslar.length, 52);
    expect(q1.lugat, 873);
    expect(q1.koplik, 340);
    expect(q1.qoida, 6);
    expect(KitobXarita.top('qiroat-2')!.lugat, 1159);
    expect(KitobXarita.top('qiroat-3')!.lugat, 1423);
    expect(KitobXarita.top('nahv-4')!.qoida, 104);
    expect(KitobXarita.top('sarf')!.qoida, 102);
  });

  for (final (id, kunlar) in [
    ('qiroat-1', 30),
    ('qiroat-1', 7),
    ('qiroat-3', 90),
    ('nahv-2', 30),
    ('sarf', 45),
  ]) {
    test('bo\'lish: $id, $kunlar kun — har birlik aynan bir marta', () {
      final reja = Reja(kitobId: id, boshKun: Reja.bugun(), kunlar: kunlar);
      final k = reja.kitob!;
      final hamma = reja.hammaElement.map((e) => e.kalit).toList();
      final yigildi = <String>[];
      final darslar = <String>{};
      for (var d = 0; d < kunlar; d++) {
        final els = reja.kunElementlari(d);
        yigildi.addAll(els.map((e) => e.kalit));
        final dd = reja.kunDarslari(d);
        expect(dd, isNotEmpty, reason: '$d-kunda dars yo\'q');
        darslar.addAll(dd.map((x) => x.id));
        if (k.lugatKitobi) {
          // Kunlik hajm teng taqsimlangan (farq ko'pi bilan 1).
          final n = hamma.length / kunlar;
          expect((els.length - n).abs() <= 1, true);
        }
      }
      expect(yigildi, hamma);
      expect(darslar.length, k.darslar.length);
    });
  }

  test('cheklist, zanjir va saqlash', () async {
    final x = RejaXotira.instance..tozala();
    final reja = await x.boshla('qiroat-1', 30);
    expect(reja.joriyKun, 0);
    for (final v in reja.vazifalar) {
      await x.belgila(reja, 0, v, true);
    }
    expect(reja.kunTugadimi(0), true);
    expect(reja.joriyKun, 1);
    expect(x.zanjir, 1);
    expect(x.bugunFaol, true);
    await x.ilgakYoz('k1', 'sahna');
    await x.load();
    expect(x.rejalar.single.tugaganKunlar, 1);
    expect(x.ilgaklar['k1'], 'sahna');
  });
}
