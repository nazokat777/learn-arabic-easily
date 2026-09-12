import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/mashq/bank.dart';

/// Sarf darsidan mashq elementlarini chiqarish.
///
/// Nega kerak: sarf darsining mazmuni «شكل – yorliq» juftliklari va 14
/// siyg'alik paradigmalar. Ular olinmasa 102 darsdan 95 tasi mashqsiz
/// qoladi — test shu yo'l yopiq turishini qo'riqlaydi.
void main() {
  SarfLesson dars(List<Map<String, dynamic>> blocks, {String title = 'T'}) =>
      SarfLesson.fromJson({
        'num': 7,
        'page': 1,
        'titleAr': '',
        'title': title,
        'blocks': blocks,
      });

  test("«ARABCHA yorliq» juftliklari moziy asosi bilan olinadi", () {
    final e = MashqBank.sarfDars(
      dars([
        {
          'type': 'matn',
          'uz':
              "وَجِيَ moziy, يَوْجَى muzore', وَجٍ sifati mushabbaha, لَمْ "
              "يَوْجَ fe'li jahd, اِيْجَ amri hozir, مِيْجَاءٌ ismi olat.",
        },
      ]),
    );
    final uz = {for (final x in e) x.ar: x.uz};
    expect(uz["يَوْجَى"], "muzore' (وَجِيَ)");
    expect(uz['لَمْ يَوْجَ'], "fe'li jahd (وَجِيَ)");
    expect(uz['مِيْجَاءٌ'], 'ismi olat (وَجِيَ)');
    expect(
      uz.containsKey('وَجِيَ'),
      isFalse,
      reason: 'asosning o\'zi savol emas',
    );
    expect(e.length, 5);
  });

  test('tire bilan yozilgan juftliklar — asos sarlavhadan', () {
    final e = MashqBank.sarfDars(
      dars([
        {
          'type': 'matn',
          'uz':
              "مَوْثُوبُ – ismi maf'ul, لَمْ يَثِبْ – fe'li jahd, ثِبْ – amri hozir",
        },
      ], title: "Misol fe'lining (وَثَبَ) sarfi"),
    );
    expect(e.map((x) => x.uz), [
      "ismi maf'ul (وَثَبَ)",
      "fe'li jahd (وَثَبَ)",
      'amri hozir (وَثَبَ)',
    ]);
  });

  test("asos bo'lmasa yorliqli juftlik olinmaydi (ikki javobli savol)", () {
    final e = MashqBank.sarfDars(
      dars([
        {'type': 'matn', 'uz': "يَوْجَى muzore', اِيْجَ amri hozir."},
      ]),
    );
    expect(e, isEmpty);
  });

  test("14 siyg'alik paradigma bo'lim sarlavhasi bilan olinadi", () {
    final e = MashqBank.sarfDars(
      dars([
        {'type': 'bolim', 'uz': "Fe'li moziyning ma'lumi"},
        {
          'type': 'matn',
          'uz':
              'وَثَبَ، وَثَبَا، وَثَبُوا، وَثَبَتْ، وَثَبَتَا، وَثَبْنَ، وَثَبْتَ، '
              'وَثَبْتُمَا، وَثَبْتُمْ، وَثَبْتِ، وَثَبْتُمَا، وَثَبْتُنَّ، '
              'وَثَبْتُ، وَثَبْنا.',
        },
        {'type': 'bolim', 'uz': 'Qoida'},
        {'type': 'matn', 'uz': 'أ، ب، ت، ث، ج، ح، خ، د، ذ، ر، ز، س، ش، ص.'},
      ]),
    );
    // Takrorlangan وَثَبْتُمَا bir marta — 13 ta element.
    expect(e.length, 13);
    expect(e.first.ar, 'وَثَبَ');
    expect(e.first.uz, "Fe'li moziyning ma'lumi · g'oib");
    expect(e[1].uz, "Fe'li moziyning ma'lumi · g'oibayn");
    expect(e.last.uz, "Fe'li moziyning ma'lumi · mutakallim ma'al g'ayr");
    expect(
      e.any((x) => x.uz.startsWith('Qoida')),
      isFalse,
      reason: "«Qoida» ostidagi ro'yxat paradigma emas",
    );
  });

  test("«ARABCHA – tarjimasi, izohi» namunalari — izoh bilan, takrorsiz", () {
    final e = MashqBank.sarfDars(
      dars([
        {
          'type': 'matn',
          'uz':
              "ضَرَبا – urdilar, ikki kishi, o'tgan zamonda, siyg'asi tasniya. "
              "ضَرَبُوا – urdilar, ko'p er kishilar, o'tgan zamonda. "
              "ضَرَبَتا – urdilar, ikki kishi, siyg'asi tasniya, muannas. "
              "مَفْرِرانِ – qoidasi yuqorida o'tdi. "
              "مَوْثُوبُ – ismi maf'ul.",
        },
      ]),
    );
    expect(e.map((x) => '${x.ar}=${x.uz}'), [
      'ضَرَبا=urdilar, ikki kishi',
      "ضَرَبُوا=urdilar, ko'p er kishilar",
    ]);
  });

  test("6 va 3 siyg'alik paradigmalar: amr — muxotab, ism — jins/son", () {
    final e = MashqBank.sarfDars(
      dars([
        {'type': 'bolim', 'uz': 'Amri hozir'},
        {
          'type': 'matn',
          'uz': 'رُدَّ، رُدَّا، رُدُّوْا، رُدِّي، رُدَّا، اُرْدُدْنَ',
        },
        {'type': 'bolim', 'uz': 'Ismi foil'},
        {
          'type': 'matn',
          'uz':
              'فَارٌّ، فَارَّانِ، فَارُّونَ، فَارَّةٌ، فَارَّتَانِ، فَارَّاتٌ',
        },
        {'type': 'bolim', 'uz': 'Ismi zamon va makon'},
        {'type': 'matn', 'uz': 'مَوْحًى، مَوْحَيَانِ، مَوَاحٍ'},
        {'type': 'bolim', 'uz': "Amri g'oib"},
        {'type': 'matn', 'uz': 'أ، ب، ت، ث، ج، ح'},
      ]),
    );
    final uz = {for (final x in e) x.ar: x.uz};
    expect(uz['رُدَّ'], 'Amri hozir · muxotab');
    expect(uz['اُرْدُدْنَ'], 'Amri hozir · muxotabot');
    expect(uz['فَارُّونَ'], "Ismi foil · muzakkar jam'");
    expect(uz['فَارَّةٌ'], 'Ismi foil · muannas vohid');
    expect(uz['مَوَاحٍ'], "Ismi zamon va makon · jam'");
    expect(uz.containsKey('أ'), isFalse, reason: "amri g'oib 6 talik emas");
  });

  test("bo'limsiz paradigma dars sarlavhasini oladi", () {
    final e = MashqBank.sarfDars(
      dars([
        {'type': 'matn', 'uz': 'دُمْ، دُومَا، دُومُوا، دُومِي، دُومَا، دُمْنَ'},
      ], title: 'دام amri hozir'),
    );
    expect(e.first.uz, 'دام amri hozir · muxotab');
    expect(e.length, 5, reason: 'takror دُومَا bir marta');
  });

  test("«X aslida Y edi» — e'lol juftligi", () {
    final e = MashqBank.sarfDars(
      dars([
        {
          'type': 'matn',
          'uz':
              "يَقْوَى aslida يَقْوَوُ edi. Bu yerda vov voqe' bo'ldi. "
              "مِيْثابٌ aslida مِوْثابٌ bo'lib, vov sokin. "
              "«لِيَفِرَّ» aslida «لِيَفْرِرْ», deb.",
        },
      ]),
    );
    expect(e.map((x) => '${x.ar}=${x.uz}'), [
      'يَقْوَى=aslida يَقْوَوُ edi',
      'مِيْثابٌ=aslida مِوْثابٌ edi',
      'لِيَفِرَّ=aslida لِيَفْرِرْ edi',
    ]);
  });

  test('jadval: oxirgi arabcha katak ↔ oxirgi o\'zbekcha katak', () {
    final e = MashqBank.sarfDars(
      dars([
        {
          'type': 'jadval',
          'sarlavha': '',
          'ustunlar': [
            {'ar': 'Vaznlar'},
            {'ar': 'Misollar'},
            {'ar': "Ma'nolari"},
          ],
          'qatorlar': [
            {
              'kataklar': ['فِعْلٌ', 'وِرْعٌ', 'yomon ishlardan saqlamoq'],
            },
            {
              'kataklar': ['Muzore\'', 'يَرِثُ'],
            },
          ],
        },
      ]),
    );
    expect(e.map((x) => '${x.ar}=${x.uz}'), [
      'وِرْعٌ=yomon ishlardan saqlamoq',
      "يَرِثُ=Muzore'",
    ]);
  });
}
