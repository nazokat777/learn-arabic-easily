import 'dart:convert';
import 'dart:io';
// Progress (XP / daraja) mantig'ining unit testlari.
//
// Eski Flutter shablon "counter smoke test"i o'chirildi — ilovada bunday
// ekran yo'q. Buning o'rniga daraja hisoblash formulasi tekshiriladi.
// Progress.xp ochiq maydon bo'lgani uchun asset/prefs yuklashsiz test qilamiz.

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/arabic.dart';
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/services/content_updater.dart';

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
      expect((Progress()..xp = 0).levelName, 'Bronza');
      // Juda katta XP oxirgi nom bilan cheklanadi (indeks xatosi bo'lmaydi).
      expect((Progress()..xp = 99999).levelName, 'Legenda');
    });
  });

  // Dars «o'zlashtirildi» belgisini FAQAT xatosiz test beradi. Bu shartning
  // buzilishi eng qimmat xato bo'lardi: belgisi bor, bilimi yo'q o'quvchi
  // keyingi darsga o'tib ketardi.
  group('Darsni o\'zlashtirish', () {
    test('xatosiz o\'tish o\'zlashtirilgan deb belgilaydi', () async {
      final p = Progress();
      expect(p.isUntried('d1'), isTrue);
      final ok = await p.recordAttempt('d1', 8, 8);
      expect(ok, isTrue);
      expect(p.isMastered('d1'), isTrue);
      expect(p.bestPercent('d1'), 100);
      // O'zlashtirgan bo'lsa, darsni ko'rib chiqqani ham aniq.
      expect(p.isCompleted('d1'), isTrue);
    });

    test('bitta xato ham o\'zlashtirishga yo\'l bermaydi', () async {
      final p = Progress();
      final ok = await p.recordAttempt('d2', 7, 8);
      expect(ok, isFalse);
      expect(p.isMastered('d2'), isFalse);
      expect(p.bestPercent('d2'), 88);
      expect(p.isUntried('d2'), isFalse);
    });

    test('eng yaxshi natija saqlanadi, yomoni uni tushirmaydi', () async {
      final p = Progress();
      await p.recordAttempt('d3', 9, 10);
      expect(p.bestPercent('d3'), 90);
      await p.recordAttempt('d3', 3, 10); // yomonroq urinish
      expect(p.bestPercent('d3'), 90);
      await p.recordAttempt('d3', 10, 10);
      expect(p.bestPercent('d3'), 100);
      expect(p.isMastered('d3'), isTrue);
    });

    test('savolsiz test o\'zlashtirish bermaydi', () async {
      final p = Progress();
      final ok = await p.recordAttempt('d4', 0, 0);
      expect(ok, isFalse);
      expect(p.isMastered('d4'), isFalse);
      // Urinish sanalmaydi — «0%» deb ko'rsatib o'quvchini chalg'itmaymiz.
      expect(p.isUntried('d4'), isTrue);
    });

    test('o\'zlashtirilmagan dars belgisiz qoladi', () async {
      final p = Progress();
      await p.recordAttempt('d5', 0, 5);
      expect(p.isMastered('d5'), isFalse);
      expect(p.isCompleted('d5'), isFalse);
      expect(p.bestPercent('d5'), 0);
    });
  });

  // «Harflarni ulash» darsi so'zni harf bo'laklariga ajratib ko'rsatadi.
  // Eng nozik joy — harakat: agar u harfdan uzilib qolsa, ekranda yolg'iz
  // suzib qoladi va dars mazmunini yo'qotadi. Shadda va tanvin bitta
  // harfda birga kelishi ham tekshiriladi.
  group('Harflarga ajratish', () {
    test('harakat o\'z harfiga qo\'shilib qoladi', () {
      expect(splitLetters('بَابٌ'), ['بَ', 'ا', 'بٌ']);
    });

    test('shadda va tanvin birga kelganda ham uzilmaydi', () {
      expect(splitLetters('زِرٌّ'), ['زِ', 'رٌّ']);
      expect(splitLetters('أُمٌّ'), ['أُ', 'مٌّ']);
    });

    test('harakatsiz so\'z ham to\'g\'ri bo\'linadi', () {
      expect(splitLetters('دار'), ['د', 'ا', 'ر']);
    });

    test('ulanmaydigan olti harf to\'g\'ri aniqlanadi', () {
      for (final h in ['ا', 'د', 'ذ', 'ر', 'ز', 'و']) {
        expect(ulanadi(h), isFalse, reason: '$h chapga ulanmasligi kerak');
      }
      for (final h in ['ب', 'ت', 'س', 'ع', 'ق', 'م']) {
        expect(ulanadi(h), isTrue, reason: '$h chapga ulanishi kerak');
      }
    });

    test('harakatli harf ham to\'g\'ri aniqlanadi', () {
      expect(ulanadi('بَ'), isTrue);
      expect(ulanadi('رٌّ'), isFalse);
    });
  });

  // Harfning so'zdagi holati — ulash darsining o'zak bilimi. Bu yerda
  // xato bo'lsa, dars o'quvchiga NOTO'G'RI narsa o'rgatadi, shuning uchun
  // klassik misollar bilan qattiq bog'lab qo'yamiz.
  group('Harf holati', () {
    test("«باب» — ا zanjirni uzadi, oxirgi ب alohida qoladi", () {
      final h = harfHolatlari(splitLetters('بَابٌ'));
      expect(h, [
        HarfHolati.boshda, // ب — ا ga ulanadi
        HarfHolati.oxirida, // ا — o'ngdan ulangan, chapga ulanmaydi
        HarfHolati.alohida, // ب — oldingi ا ulanmagani uchun yolg'iz
      ]);
    });

    test("«كتاب» — o'rtadagi ت ikki tomondan ulanadi", () {
      final h = harfHolatlari(splitLetters('كِتَابٌ'));
      expect(h, [
        HarfHolati.boshda,
        HarfHolati.ortada,
        HarfHolati.oxirida,
        HarfHolati.alohida,
      ]);
    });

    test("«دار» — hamma harfi ulanmaydigan so'zda o'rta holat bo'lmaydi", () {
      final h = harfHolatlari(splitLetters('دَارٌ'));
      expect(h.contains(HarfHolati.ortada), isFalse);
      expect(h.first, HarfHolati.alohida); // د chapga ulanmaydi
    });

    test("«قلم» — hammasi ulanadigan so'z: bosh, o'rta, oxir", () {
      final h = harfHolatlari(splitLetters('قَلَمٌ'));
      expect(h, [HarfHolati.boshda, HarfHolati.ortada, HarfHolati.oxirida]);
    });

    test('shakl tatweel bilan yasaladi va harakatsiz bo\'ladi', () {
      // Tatweel (U+0640) — ko'rinadigan ulanish chizig'i.
      //
      // Ilgari ko'rinmas ZWJ (U+200D) ishlatilardi va ilovada harf
      // BOSHLANG'ICH shakl o'rniga ALOHIDA shaklda chizilardi: «جـ»
      // o'rniga «ج». Ko'rinmas belgi shaper va matn yo'nalishiga bog'liq
      // bo'lib qolgan edi.
      expect(holatShakli('بَ', HarfHolati.boshda), 'بـ');
      expect(holatShakli('بَ', HarfHolati.ortada), 'ـبـ');
      expect(holatShakli('بٌ', HarfHolati.oxirida), 'ـب');
      expect(holatShakli('بٌ', HarfHolati.alohida), 'ب');
    });

    test('ulanadigan harfda to\'rt shakl bir-biridan farq qiladi', () {
      // Aynan shu buzilgandi: «So'z BOSHIDA» ostida ALOHIDA shakl
      // chiqardi. Shakllar bir xil bo'lib qolsa, bo'lim hech narsa
      // o'rgatmaydi — shuning uchun farqni majburiy qilamiz.
      const b = 'ب';
      final shakllar = {for (final h in HarfHolati.values) holatShakli(b, h)};
      expect(
        shakllar.length,
        HarfHolati.values.length,
        reason: 'to\'rt shakl ham bir-biridan farq qilishi kerak: $shakllar',
      );
    });
  });

  // Yangilanish manzili. Bu yerda bir marta xato qilingandi: Dart satrida
  // dollar belgilari qochirib qo'yilgani uchun manzil so'zma-so'z
  // "$baseUrl/$name?t=${...}" bo'lib chiqqandi. `flutter analyze` buni
  // ushlamaydi — satrning o'zi to'g'ri. Natijada BARCHA yangilanishlar
  // jimgina ishlamay qolardi, ya'ni telefondagi ilova yangi darslarni
  // hech qachon ko'rmasdi. Shuning uchun manzil shakli testga bog'landi.
  group('Kontent yangilanishi', () {
    test('manzil to\'g\'ri yasaladi (interpolatsiya ishlaydi)', () {
      final u = ContentUpdater.instance.uriFor('nahv_lessons.json');
      expect(u.scheme, 'https');
      expect(u.host, 'nazokat777.github.io');
      expect(u.path, endsWith('/content/nahv_lessons.json'));
      expect(
        u.toString(),
        isNot(contains(r'$')),
        reason: 'manzilda so\'zma-so\'z dollar qolmasligi kerak',
      );
    });

    test('har chaqiruvda kesh chetlab o\'tiladi', () async {
      final a = ContentUpdater.instance.uriFor('version.json');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final b = ContentUpdater.instance.uriFor('version.json');
      expect(
        a.queryParameters['t'],
        isNotNull,
        reason: 'kesh chetlab o\'tish parametri yo\'q',
      );
      expect(
        a.toString(),
        isNot(b.toString()),
        reason: 'manzil har safar boshqacha bo\'lishi kerak',
      );
    });

    test('yangilanadigan fayllar ro\'yxati to\'liq', () {
      // Yangi kontent fayli qo'shilganda uni ro'yxatga kiritish esdan
      // chiqsa, u telefonga hech qachon yetib bormaydi.
      expect(
        ContentUpdater.files,
        containsAll([
          'letters.json',
          'harakat.json',
          'vocabulary.json',
          'qiroat_lessons.json',
          'nahv_lessons.json',
          'ulash.json',
        ]),
      );
    });
  });

  // Harakatlar testining «qanday unli tovush beradi?» turi.
  //
  // Bu yerda haqiqiy xato bo'lgan: ekranda «بَ» ko'rsatilib, variantlar
  // «a, un, bb, i» bo'lardi. «بَ» esa «ba» deb o'qiladi, ya'ni savolga
  // to'g'ri javob yo'qdek tuyulardi; ustiga «bb» (shadda) umuman unli
  // emas edi. Shart shu: bu turda faqat UNLI beradigan harakatlar
  // qatnashsin va ular 4 ta variantga yetsin.
  group('Harakat savoli', () {
    const unliBermaydi = {'-', 'bb'};

    List<Map<String, dynamic>> harakatlar() =>
        (json.decode(
                  File('assets/content/harakat.json').readAsStringSync(),
                )['harakat']
                as List)
            .cast<Map<String, dynamic>>();

    test('unli beradigan harakatlar 4 ta variantga yetadi', () {
      final unlilar = harakatlar()
          .map((h) => (h['sound_uz'] as String).trim())
          .where((s) => !unliBermaydi.contains(s))
          .toSet();
      expect(
        unlilar.length,
        greaterThanOrEqualTo(4),
        reason: 'to\'rt variant yasash uchun kamida 4 xil unli kerak',
      );
    });

    test('unli tovushlar takrorlanmaydi', () {
      // Ikki harakatning tovushi bir xil bo'lsa, variantlar ichida bir xil
      // javob ikki marta chiqadi va biri «xato» deb belgilanadi.
      final ro = harakatlar()
          .map((h) => (h['sound_uz'] as String).trim())
          .where((s) => !unliBermaydi.contains(s))
          .toList();
      expect(ro.toSet().length, ro.length, reason: 'takror tovush: $ro');
    });

    test('sukun va shadda unli sifatida so\'ralmaydi', () {
      final nomlar = <String, String>{
        for (final h in harakatlar())
          (h['sound_uz'] as String).trim(): h['name_uz'] as String,
      };
      // Sukun unli bermaydi, shadda esa undoshni ikkilantiradi — ikkalasi
      // ham «qanday unli beradi?» savoliga javob bo'la olmaydi.
      expect(nomlar['-'], 'Sukun');
      expect(nomlar['bb'], 'Shadda');
    });
  });

  group('Kontent yaxlitligi', () {
    test("harakatlar o'z harfiga ulangan (ajralib qolmagan)", () {
      final buzuq = <String>[];
      for (final f in [
        'assets/content/qiroat_lessons.json',
        'assets/content/nahv_lessons.json',
        'assets/content/vocabulary.json',
        'assets/content/letters.json',
        'assets/content/harakat.json',
      ]) {
        final matnlar = <String>[];
        _matnlarniYig(json.decode(File(f).readAsStringSync()), matnlar);
        for (final m in matnlar) {
          if (_harakatAjralganmi(m)) buzuq.add('$f: $m');
        }
      }
      expect(buzuq, isEmpty, reason: 'harakati ajralgan yozuvlar: $buzuq');
    });
  });
}

/// Harakatlar o'z harfiga ulanganini tekshiradi.
///
/// Nega kerak: PDF'dan matn ko'chirishda harakatlar ba'zan so'zning oxiriga
/// to'planib qoladi («تفرس» + «ََّ»). Ko'zga tashlanmaydi — harakatlarni olib
/// tashlasa ikkala shakl bir xil — lekin ekranda harakat harfga ulanmay
/// suzib turadi va TTS unlilarni umuman o'qimaydi. Buni keyin dastur bilan
/// tiklab bo'lmaydi, shuning uchun testda ushlaymiz.
bool _harakatAjralganmi(String s) {
  const harakat = {
    0x064B,
    0x064C,
    0x064D,
    0x064E,
    0x064F,
    0x0650,
    0x0651,
    0x0652,
    0x0653,
    0x0654,
    0x0655,
    0x0670,
  };
  // harakat.json da harakatning O'ZI alohida saqlanadi («َ») — u xato emas.
  if (s.runes.every((r) => harakat.contains(r))) return false;
  var ketmaKet = 0;
  var birinchi = true;
  for (final r in s.runes) {
    final belgi = harakat.contains(r);
    if (belgi && birinchi) return true; // so'z harakat bilan boshlanmaydi
    if (!(r == 0x20 || r == 0x0A)) birinchi = false;
    ketmaKet = belgi ? ketmaKet + 1 : 0;
    // Ketma-ket uchta harakat arab yozuvida uchramaydi (shadda + harakat = 2).
    if (ketmaKet >= 3) return true;
  }
  return false;
}

void _matnlarniYig(dynamic o, List<String> out) {
  if (o is String) {
    out.add(o);
  } else if (o is List) {
    for (final v in o) {
      _matnlarniYig(v, out);
    }
  } else if (o is Map) {
    for (final v in o.values) {
      _matnlarniYig(v, out);
    }
  }
}
