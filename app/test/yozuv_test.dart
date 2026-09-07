// Ilova matnlari lotin yozuvida saqlanishi kerak.
//
// Nega: kirillcha ko'rinish `UzYozuv` orqali hosil qilinadi. Manba kodda
// kirillcha qolib ketgan so'z LOTIN rejimida ham kirillcha bo'lib turadi —
// «28 harf, махраж, harakatlar» kabi aralash satr shundan chiqqan edi.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kirill harflari (lotin «i», «o» kabi umumiy belgilar emas).
final _kirill = RegExp('[Ѐ-ӿ]');

/// Ataylab kirillcha qoladigan joylar: yozuvni almashtirish tugmasining
/// yorlig'i («Кирилл») va kirill↔lotin jadvali.
const _ruxsat = {'lib/uz_yozuv.dart'};

void main() {
  test('lib/ ichidagi matn satrlarida kirillcha so\'z yo\'q', () {
    final aybdorlar = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final yol = f.path.replaceAll('\\', '/');
      if (_ruxsat.contains(yol)) continue;
      final satrlar = f.readAsLinesSync();
      for (var i = 0; i < satrlar.length; i++) {
        final s = satrlar[i];
        final t = s.trimLeft();
        // Izohlar tekshirilmaydi — ular foydalanuvchiga ko'rinmaydi.
        if (t.startsWith('//')) continue;
        if (!_kirill.hasMatch(s)) continue;
        // Yozuv tugmasining o'z yorlig'i.
        if (s.contains('Кирилл')) continue;
        aybdorlar.add('$yol:${i + 1}: ${t.trim()}');
      }
    }
    expect(aybdorlar, isEmpty, reason: aybdorlar.join('\n'));
  });
}
