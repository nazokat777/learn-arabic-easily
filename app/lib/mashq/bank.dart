import '../arabic.dart';
import '../content.dart';
import '../main.dart';
import 'element.dart';

/// Har modulning mazmunidan mashq elementlarini yasaydi.
///
/// Bitta joyda turishining sababi: «shu darsgacha bo'lgan hamma narsa»
/// degan takror har modulda bir xil ishlashi kerak, ya'ni elementlarni
/// yig'ish qoidasi ham bitta bo'lishi shart. Aks holda bir modulda
/// takror lug'atni, boshqasida qoidani olib qolardi.
class MashqBank {
  MashqBank._();

  /// Variant qilib ko'rsatish uchun juda uzun bo'lgan matnni chiqarib
  /// tashlaymiz: ekranda sig'maydigan variant savolni buzadi.
  static const int _maxUzunlik = 90;

  static bool _yaroqli(String ar, String uz) =>
      ar.trim().isNotEmpty &&
      uz.trim().isNotEmpty &&
      stripDiacritics(ar).length <= _maxUzunlik &&
      uz.length <= 120;

  // ---------------- Mabdaul qiroat ----------------

  static List<MashqElement> qiroatDars(QiroatLesson l) {
    final korilgan = <String>{};
    final natija = <MashqElement>[];
    for (final v in l.vocab) {
      final ar = splitForms(v.ar).first;
      if (!_yaroqli(ar, v.uz) || !korilgan.add(v.uz)) continue;
      natija.add(
        MashqElement(
          kalit: 'qiroat::${l.completionId}::${v.ar}',
          ar: ar,
          uz: v.uz,
          darsId: l.completionId,
          tartib: l.book * 1000 + l.num,
          modul: 'Mabdaul qiroat',
        ),
      );
    }
    return natija;
  }

  /// Shu darsgacha (shu dars ham) bo'lgan hamma lug'at.
  static List<MashqElement> qiroatGacha(QiroatLesson l) {
    final chegara = l.book * 1000 + l.num;
    final natija = <MashqElement>[];
    for (final x in repo.qiroatLessons) {
      if (x.book * 1000 + x.num > chegara) continue;
      natija.addAll(qiroatDars(x));
    }
    return natija;
  }

  // ---------------- Nahv ----------------

  static List<MashqElement> _nahvJuftlar(NahvLesson l) {
    final juftlar = <NahvPair>[
      l.rule,
      for (final b in l.blocks) ...[
        if (b.main != null) b.main!,
        if (b.intro != null) b.intro!,
        ...b.items,
      ],
    ];
    final korilgan = <String>{};
    final natija = <MashqElement>[];
    for (final p in juftlar) {
      if (!_yaroqli(p.ar, p.uz) || !korilgan.add(p.ar)) continue;
      natija.add(
        MashqElement(
          kalit: 'nahv::${l.book}-${l.num}::${p.ar}',
          ar: p.ar,
          uz: p.uz,
          darsId: 'nahv-${l.book}-${l.num}',
          tartib: l.book * 1000 + l.num,
          modul: 'Nahv',
        ),
      );
    }
    return natija;
  }

  static List<MashqElement> nahvDars(NahvLesson l) => _nahvJuftlar(l);

  static List<MashqElement> nahvGacha(NahvLesson l) {
    final chegara = l.book * 1000 + l.num;
    final natija = <MashqElement>[];
    for (final x in repo.nahvLessons) {
      if (x.book * 1000 + x.num > chegara) continue;
      natija.addAll(_nahvJuftlar(x));
    }
    return natija;
  }

  // ---------------- Sarf ----------------

  /// Sarf darsidan juftlik chiqarish.
  ///
  /// Kitob matni o'zbekcha, arabcha misollar gap ichida keladi. Ikki
  /// joydan juftlik olinadi:
  ///   * «misol» bloklari — arabcha satr va uning izohi;
  ///   * ro'yxat bandlari «Ism — اسم» ko'rinishida bo'lsa, tire bo'yicha
  ///     ikkiga bo'linadi. Aynan shu bandlar kitobning atama lug'ati.
  /// «صَحِيحْ (sahih).» — arabcha
  /// atama va qavs ichidagi o'zbekcha o'qilishi.
  static final RegExp _qavsliAtama = RegExp(
    r'^([\u0600-\u06FF\u0750-\u077F\s]+)\(([^)]+)\)\.?$',
  );

  static List<MashqElement> sarfDars(SarfLesson l) {
    final korilgan = <String>{};
    final natija = <MashqElement>[];

    void qosh(String ar, String uz) {
      if (!_yaroqli(ar, uz) || !korilgan.add(ar)) return;
      natija.add(
        MashqElement(
          kalit: 'sarf::${l.num}::$ar',
          ar: ar,
          uz: uz,
          darsId: l.completionId,
          tartib: l.num,
          modul: 'Sarf',
        ),
      );
    }

    for (final b in l.blocks) {
      if (b.type == 'misol') {
        qosh(b.ar, b.uz);
        continue;
      }
      for (final band in b.items) {
        // «صَحِيحْ (sahih).» — kitob
        // atamalarni shu ko'rinishda ham beradi.
        final qavs = _qavsliAtama.firstMatch(band);
        if (qavs != null) {
          qosh(qavs.group(1)!.trim(), qavs.group(2)!.trim());
          continue;
        }
        final bolak = band.split(RegExp(r'\s[—–-]\s'));
        if (bolak.length != 2) continue;
        final chap = bolak[0].trim();
        final ong = bolak[1].trim();
        // Qaysi tomon arabcha ekanini aniqlaymiz.
        final ongArab = RegExp(r'[؀-ۿ]').hasMatch(ong);
        final chapArab = RegExp(r'[؀-ۿ]').hasMatch(chap);
        if (ongArab && !chapArab) {
          qosh(ong, chap);
        } else if (chapArab && !ongArab) {
          qosh(chap, ong);
        }
      }
    }
    return natija;
  }

  static List<MashqElement> sarfGacha(SarfLesson l) {
    final natija = <MashqElement>[];
    for (final x in repo.sarfLessons) {
      if (x.num > l.num) continue;
      natija.addAll(sarfDars(x));
    }
    return natija;
  }

  // ---------------- Alifbo ----------------

  static List<MashqElement> harflar() => [
    for (final h in repo.letters)
      MashqElement(
        kalit: 'alifbo::harf::${h.ar}',
        ar: h.ar,
        uz: h.nameUz,
        darsId: 'letter_test',
        tartib: h.id,
        modul: 'Alifbo',
      ),
  ];

  static List<MashqElement> harakatlar() => [
    for (final h in repo.harakat)
      MashqElement(
        kalit: 'alifbo::harakat::${h.nameUz}',
        ar: h.exampleAr,
        uz: h.nameUz,
        darsId: 'harakat_test',
        tartib: 100 + h.id,
        modul: 'Harakatlar',
      ),
  ];

  /// Alifbo bo'limi uchun «shu paytgacha hammasi» — harflar va harakatlar.
  static List<MashqElement> alifboGacha() => [...harflar(), ...harakatlar()];
}
