// Mad harflari: fatha+ا, zamma+و, kasra+ي — harakatsiz (yoki sukunli)
// harf cho'ziq unli; harakatli «و/ي» (وَلَد, يَد) mad emas.

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/arabic.dart';

void main() {
  test('mad harflari aniqlanadi', () {
    expect(madHarflari(splitLetters('كِتَاب')), [false, false, true, false]);
    expect(madHarflari(splitLetters('نُور')), [false, true, false]);
    expect(madHarflari(splitLetters('فِيل')), [false, true, false]);
    // Harakatli و/ي — mad emas; ا oldida fatha bo'lmasa — mad emas.
    expect(madHarflari(splitLetters('وَلَد')), [false, false, false]);
    expect(madHarflari(splitLetters('يَد')), [false, false]);
    expect(madHarflari(splitLetters('إِنْسَان')), [
      false,
      false,
      false,
      true,
      false,
    ]);
  });
}
