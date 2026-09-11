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

  /// Dars matnidagi «ARABCHA – yorliq» juftliklari: «مَوْثُوبُ – ismi
  /// maf'ul», «يَوْجَى muzore'». Sarf darsining asosiy mazmuni aynan shu
  /// hosila shakllar — ular mashqqa tushmasa, dars mashqsiz qoladi.
  static final RegExp _hosila = RegExp(
    r"([؀-ۿ][؀-ۿ\s]*?)\s*(?:–|-|—)?\s*"
    r"(moziy|muzore'|ismi fo'il|ismi foil|ismi maf'ul|sifati mushabbaha|"
    r"fe'li jahd|fe'li nafiy|amri hozir|amr hozir|amri g'oib|amri g'oyib|"
    r"fe'li nahiy|nahiy hozir|ismi zamon va makon|ismi olati|ismi olat|"
    r"ismi tafzil|masdar)(?=[\s,.;:!)]|$)",
  );

  /// Kitobning 14 siyg'a tartibi — paradigma bloklari shu tartibda.
  static const List<String> _siygalar = [
    "g'oib",
    "g'oibayn",
    "g'oibin",
    "g'oibah",
    "g'oibatayn",
    "g'oibot",
    'muxotab',
    'muxotabayn',
    'muxotabin',
    'muxotabah',
    'muxotabatayn',
    'muxotabot',
    'mutakallimi vohid',
    "mutakallim ma'al g'ayr",
  ];

  static final RegExp _lotin = RegExp('[A-Za-z]');
  static final RegExp _arabcha = RegExp('[؀-ۿ]');
  static final RegExp _sarlavhaQavs = RegExp(r'\(([؀-ۿ\s]+)\)');

  /// Apostrof variantlarini birlashtiradi — matnda ' ʼ ‘ ’ aralash.
  static String _apostrof(String s) =>
      s.replaceAll('ʼ', "'").replaceAll('‘', "'").replaceAll('’', "'");

  /// Paradigma bloki sarlavhasi fe'l shaklini bildiradimi («Fe'li
  /// moziyning ma'lumi»). «Qoida», «Sarfi» kabi sarlavha ostidagi
  /// ro'yxat qaysi shakl ekani noaniq — o'tkazib yuboriladi.
  static bool _paradigmaSarlavhasi(String s) {
    final k = _apostrof(s).toLowerCase();
    return k.contains("fe'l") ||
        k.contains('moziy') ||
        k.contains('muzore') ||
        k.contains('jahd') ||
        k.contains('nafiy') ||
        k.contains('nahiy') ||
        k.contains('amr');
  }

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

    // Sarlavhadagi fe'l — «Misol fe'lining (وَثَبَ) sarfi».
    final sarlavhaAsos = _sarlavhaQavs.firstMatch(l.title)?.group(1)?.trim();
    String? oxirgiBolim;

    for (final b in l.blocks) {
      if (b.type == 'misol') {
        qosh(b.ar, b.uz);
        continue;
      }
      if (b.type == 'bolim') {
        oxirgiBolim = b.uz.trim();
        continue;
      }
      if (b.type == 'jadval') {
        // Oxirgi arabcha katak ↔ oxirgi o'zbekcha katak: vazn jadvalida
        // «misol ↔ ma'no», shakl jadvalida «arabcha ↔ shakl nomi».
        for (final q in b.qatorlar) {
          final ar = q.kataklar.where(_arabcha.hasMatch).toList();
          final uz = q.kataklar
              .where((c) => c.trim().isNotEmpty && !_arabcha.hasMatch(c))
              .toList();
          if (ar.isNotEmpty && uz.isNotEmpty) qosh(ar.last.trim(), uz.last.trim());
        }
        continue;
      }
      if (b.type == 'matn') {
        final matn = _apostrof(b.uz);
        // 14 siyg'alik paradigma — sarlavhasi bilan.
        final bolim = oxirgiBolim;
        final bolaklar = matn
            .replaceAll(RegExp(r'\.\s*$'), '')
            .split(RegExp('[،,]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (bolaklar.length == _siygalar.length &&
            bolim != null &&
            _paradigmaSarlavhasi(bolim) &&
            bolaklar.every((s) => _arabcha.hasMatch(s) && !_lotin.hasMatch(s))) {
          for (var i = 0; i < bolaklar.length; i++) {
            qosh(bolaklar[i], '$bolim · ${_siygalar[i]}');
          }
          continue;
        }
        // «ARABCHA – yorliq» juftliklari; asos — shu blokdagi moziy yoki
        // sarlavhadagi fe'l. Asossiz «muzore'» yorlig'i ko'p fe'lga
        // to'g'ri keladi va savolni ikki javobli qilib qo'yadi.
        final topilgan = _hosila.allMatches(matn).toList();
        String? asos = sarlavhaAsos;
        for (final m in topilgan) {
          if (m.group(2) == 'moziy') asos = m.group(1)!.trim();
        }
        if (asos == null) continue;
        for (final m in topilgan) {
          final ar = m.group(1)!.trim();
          final yorliq = m.group(2)!;
          if (yorliq == 'moziy' || ar == asos) continue;
          qosh(ar, '$yorliq ($asos)');
        }
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

  // ---------------- Qiyin so'zlar (modullar aro) ----------------

  /// Ilovadagi BARCHA mashq elementlari.
  static List<MashqElement> hammasi() => [
    ...alifboGacha(),
    for (final l in repo.qiroatLessons) ...qiroatDars(l),
    for (final l in repo.nahvLessons) ...nahvDars(l),
    for (final l in repo.sarfLessons) ...sarfDars(l),
  ];

  /// O'quvchi ko'p adashgan («qiyin») elementlar — hamma moduldan.
  ///
  /// Eng ko'p xato qilingani birinchi: mashq aynan shundan boshlansin.
  static List<MashqElement> qiyinlar() {
    final r = hammasi().where((e) => progress.qiyinMi(e.kalit)).toList();
    r.sort(
      (a, b) =>
          progress.xatoSoni(b.kalit).compareTo(progress.xatoSoni(a.kalit)),
    );
    return r;
  }

  /// Qiyin so'zlar mashqi uchun chalg'ituvchilar havzasi.
  ///
  /// Qiyin so'z uch-to'rttagina bo'lsa, variant yetmaydi va savol
  /// yasalmaydi — shuning uchun havzaga o'sha modullardan bir nechta
  /// oddiy element qo'shiladi.
  static List<MashqElement> qiyinHavzasi(List<MashqElement> qiyin) {
    if (qiyin.length >= 6) return qiyin;
    final modullar = qiyin.map((e) => e.modul).toSet();
    final qoshimcha = hammasi()
        .where((e) => modullar.contains(e.modul) && !progress.qiyinMi(e.kalit))
        .take(12)
        .toList();
    return [...qiyin, ...qoshimcha];
  }
}
