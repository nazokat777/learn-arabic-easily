import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/rasm.dart';

/// Konkret otlar rasmi: faqat aynan mos kelganda, fe'l va mavhum so'zga
/// hech qachon.
void main() {
  test("aynan mos kelgan konkret ot — rasm bor", () {
    expect(Rasm.topish('kitob'), '📖');
    expect(Rasm.topish('Mushuk (2)'), '🐈');
    expect(Rasm.topish('maktab, madrasa'), '🏫');
    expect(Rasm.topish('bir uy'), '🏠');
    expect(Rasm.topish("qo'y"), '🐑');
  });

  test("fe'l, mavhum so'z va qisman o'xshashga rasm yo'q", () {
    expect(Rasm.topish('yugurmoq'), isNull);
    expect(Rasm.topish('mashaqqat'), isNull);
    expect(Rasm.topish('kitoblar'), isNull, reason: 'faqat aynan mos');
    expect(Rasm.topish('yoz'), isNull, reason: "«yoz» — yozmoq ham, yoz fasli ham");
    expect(Rasm.topish(''), isNull);
  });
}
