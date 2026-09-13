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
      // «وَقَدْ تَكُونُ الْكَلِمَةُ:» kabi ro'yxat sarlavhasi — savol emas.
      if (p.ar.trim().endsWith(':') || p.uz.trim().endsWith(':')) continue;
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

  /// Nahv ro'yxatlaridagi tasnif: «Fe'l; masalan: كَتَبَ، يَكْتُبُ…»,
  /// «Ism; masalan: مُحَمَّد…», «Muzakkar … masalan: عَلِيّ…». Kitob
  /// o'zi bergan misollar o'z turi bilan — «كَتَبَ qaysi turga kiradi?».
  ///
  /// QAT'IY qoidalar (taxmin yo'q): faqat «مِثْلُ:» / «نَحْوُ:» dan
  /// keyingi bo'lak; nuqta, «؛» yoki «وَغَيْرِ» gacha; «،» bilan bo'lingan
  /// BIR SO'ZLI arabcha misollar (bosh «وَ»/«أَوْ» tashlanadi); oyat (﴿),
  /// «جَمْعِ» kabi izohli misol — tashlanadi. Tur nomi — o'zbekcha bandning
  /// boshi (birinchi «;», « —», «:» gacha), qisqa va lotin. Bitta ro'yxat
  /// = bitta guruh; kamida ikki xil tur bo'lishi shart. Bir so'z ikki
  /// turda kelsa — tashlanadi.
  static List<(String, String)> nahvTurkum(NahvBlock b) => [
    for (final (a, u, _) in nahvTurkumIzohli(b)) (a, u),
  ];

  /// Tasnif juftliklari kitob ta'rifi bilan: (kalima, tur, ta'rif).
  /// Ta'rif — o'zbekcha bandda tur nomidan «masalan»gacha bo'lgan qism
  /// («Mozi — o'tgan zamonda … fe'l; masalan: …» → o'rta qismi); bo'lmasa ''.
  static List<(String, String, String)> nahvTurkumIzohli(NahvBlock b) {
    if (b.type != 'list') return const [];
    final misolBoshi = RegExp(r'(?:مِثْلُ|نَحْوُ)\s*:');
    final natija = <(String, String, String)>[];
    final turlar = <String>{};
    final korilgan = <String, String>{};
    final ziddiyat = <String>{};
    for (final it in b.items) {
      final m = misolBoshi.firstMatch(it.ar);
      if (m == null) continue;
      final izoh = _turIzohi(it.uz);
      var bolak = it.ar.substring(m.end);
      final kes = RegExp('[.؛]|وَغَيْرِ').firstMatch(bolak);
      if (kes != null) bolak = bolak.substring(0, kes.start);
      if (bolak.contains('﴿') || bolak.contains('جَمْعِ')) continue;
      final tur = _turNomi(it.uz);
      if (tur == null) continue;
      final sozlar = <String>[];
      for (var s in bolak.split('،')) {
        s = s.replaceAll(RegExp('[«»]'), '').trim();
        if (s.isEmpty) continue; // oxirgi «،» dan keyingi bo'shliq
        // «أَوْ X» — muqobil shakl; «وَX» — bog'lovchi bilan.
        s = s.replaceFirst(RegExp(r'^(?:أَوْ|وَ)\s*'), '').trim();
        if (s.isEmpty || s.contains(' ') || !_arabcha.hasMatch(s)) {
          sozlar.clear();
          break; // shubhali bo'lak — butun band tashlanadi
        }
        if (_lotin.hasMatch(s)) {
          sozlar.clear();
          break;
        }
        sozlar.add(s);
      }
      if (sozlar.isEmpty) continue;
      turlar.add(tur);
      for (final s in sozlar) {
        final oldingi = korilgan[s];
        if (oldingi != null && oldingi != tur) ziddiyat.add(s);
        if (oldingi == null) {
          korilgan[s] = tur;
          natija.add((s, tur, izoh));
        }
      }
    }
    if (turlar.length < 2) return const [];
    return [
      for (final (s, tur, iz) in natija)
        if (!ziddiyat.contains(s)) (s, tur, iz),
    ];
  }

  /// «Mozi — o'tgan zamonda … fe'l; masalan: …» → «o'tgan zamonda … fe'l».
  /// Tur nomidan keyingi ajratgich («—», «;», «:») dan «masalan» gacha;
  /// qisqa (< 12 belgi) yoki yo'q bo'lsa — ''.
  static String _turIzohi(String uz) {
    final s = uz.trim();
    final bosh = RegExp(r'[;:]| — | – ').firstMatch(s);
    if (bosh == null) return '';
    var qolgan = s.substring(bosh.end).trim();
    final oxir = RegExp(r'[;:]?\s*masalan').firstMatch(qolgan);
    if (oxir != null) qolgan = qolgan.substring(0, oxir.start).trim();
    qolgan = qolgan.replaceAll(RegExp(r'[;:—–]+$'), '').trim();
    if (qolgan.length < 12 || !_lotin.hasMatch(qolgan)) return '';
    return qolgan;
  }

  /// O'zbekcha banddan tur nomi: «Fe'l; masalan: …» → «Fe'l»,
  /// «Muzakkar — erkak zotga…» → «Muzakkar». Uzun yoki lotinsiz — null.
  static String? _turNomi(String uz) {
    var s = uz.trim();
    final kes = RegExp(r'[;:]| — | – |\(').firstMatch(s);
    if (kes != null) s = s.substring(0, kes.start);
    s = s.trim();
    if (s.isEmpty || s.length > 32 || !_lotin.hasMatch(s)) return null;
    if (_arabcha.hasMatch(s)) return null;
    return s;
  }

  /// Nahv darsining tasnif elementlari (ro'yxat bo'yicha guruhlangan).
  static List<MashqElement> nahvTurkumlar(NahvLesson l) {
    final natija = <MashqElement>[];
    for (final (i, b) in l.blocks.indexed) {
      for (final (ar, uz, izoh) in nahvTurkumIzohli(b)) {
        if (!_yaroqli(ar, uz)) continue;
        natija.add(
          MashqElement(
            kalit: 'nahv::${l.book}-${l.num}::tur::$ar',
            ar: ar,
            uz: uz,
            darsId: 'nahv-${l.book}-${l.num}',
            tartib: l.book * 1000 + l.num,
            modul: 'Nahv',
            ovoz: '',
            turkum: true,
            guruh: 'nahv-${l.book}-${l.num}-$i',
            izoh: izoh,
          ),
        );
      }
    }
    return natija;
  }

  /// Dars mashqi: qoida/misol juftliklari + ro'yxatlardan tasnif.
  static List<MashqElement> nahvDars(NahvLesson l) => [
    ..._nahvJuftlar(l),
    ...nahvTurkumlar(l),
  ];

  static List<MashqElement> nahvGacha(NahvLesson l) {
    final chegara = l.book * 1000 + l.num;
    final natija = <MashqElement>[];
    for (final x in repo.nahvLessons) {
      if (x.book * 1000 + x.num > chegara) continue;
      natija.addAll(_nahvJuftlar(x));
      natija.addAll(nahvTurkumlar(x));
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

  /// «ARABCHA – tarjimasi, izohi, siyg'asi …» — nazariy boblardagi
  /// namuna jumlalar («ضَرَبا – urdilar, ikki kishi, o'tgan zamonda…»).
  /// Tarjima va birinchi izoh olinadi: faqat tarjima («urdilar») bir
  /// necha shaklga to'g'ri kelib, savolni ikki javobli qilardi.
  static final RegExp _tarjima = RegExp(
    r"([؀-ۿ][؀-ۿ\s]*?)\s[–—-]\s([^,،.;:()]+)(?:[,،]\s*([^,،.;:()]+))?",
  );

  /// Tarjima o'rnida yorliq yoki qoida bo'lsa — bu tarjima emas.
  static bool _tarjimaEmas(String uz) {
    final k = _apostrof(uz).toLowerCase();
    const yorliqlar = [
      'moziy',
      'muzore',
      'ismi ',
      'sifati ',
      "fe'li ",
      'amri ',
      'amr ',
      'nahiy',
      'masdar',
      'qoida',
      'yuqorida',
      'vazni',
      'aslida',
    ];
    return yorliqlar.any(k.startsWith) || k.contains('qoida');
  }

  /// Ismlarning olti siyg'asi (ismi foil, maf'ul, tafzil) — kitob tartibi.
  static const List<String> _ismSiygalari = [
    'muzakkar vohid',
    'muzakkar tasniya',
    "muzakkar jam'",
    'muannas vohid',
    'muannas tasniya',
    "muannas jam'",
  ];

  /// Ismi zamon/makon va ismi olatning uch siyg'asi.
  static const List<String> _uchSiyga = ['vohid', 'tasniya', "jam'"];

  /// «X aslida Y edi» — e'lol juftligi: hozirgi shakl ↔ asl shakli.
  /// Sarfning asl mashqi shu: qoidani qo'llab, asldan hozirgi shaklga
  /// (va teskarisiga) o'ta olish.
  static final RegExp _asl = RegExp(
    r"([؀-ۿ][؀-ۿ\s]*?)»?\s+aslida\s+(?:–\s+)?«?([؀-ۿ][؀-ۿ\s]*?)»?\s*"
    r"(?:edi|bo'lib|bo'lgan|deb|,|\.)",
  );

  /// Paradigma blokining yorlig'iga qarab siyg'a nomlarini tanlaydi.
  /// Mos kelmasa `null` — ro'yxat paradigma emas yoki turi noaniq.
  static List<String>? _siygaNomlari(int soni, String yorliq) {
    final k = _apostrof(yorliq).toLowerCase();
    switch (soni) {
      case 14:
        return _paradigmaSarlavhasi(yorliq) ? _siygalar : null;
      case 6:
        if (k.contains('amr') && !k.contains("g'oib")) {
          return _siygalar.sublist(6, 12); // muxotab … muxotabot
        }
        return k.contains('ism') ? _ismSiygalari : null;
      case 3:
        return k.contains('ism') ? _uchSiyga : null;
    }
    return null;
  }

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

  /// Matn bloki paradigmami (14, 6 yoki 3 siyg'alik arabcha ro'yxat):
  /// bo'lsa — (shakl, siyg'a nomi) juftliklari, aks holda `null`.
  /// Mashq ham, dars ekrani ham shu bitta qoidadan foydalanadi —
  /// ikkisi bir-biridan ajralib ketmasin.
  static List<(String, String)>? paradigma(String matn, String yorliq) {
    final bolaklar = _apostrof(matn)
        .replaceAll(RegExp(r'\.\s*$'), '')
        .split(RegExp('[،,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (bolaklar.isEmpty ||
        !bolaklar.every((s) => _arabcha.hasMatch(s) && !_lotin.hasMatch(s))) {
      return null;
    }
    final nomlar = _siygaNomlari(bolaklar.length, yorliq);
    if (nomlar == null) return null;
    return [for (var i = 0; i < bolaklar.length; i++) (bolaklar[i], nomlar[i])];
  }

  /// Darsdagi mashq elementlari soni — ro'yxat uchun keshlangan
  /// (kontent faqat qayta ochilganda o'zgaradi).
  static final Map<int, int> _sarfSoni = {};
  static int sarfSoni(SarfLesson l) =>
      _sarfSoni.putIfAbsent(l.num, () => sarfDars(l).length);

  /// Ro'yxat yozuvi: «12 ta mashq · 25 tasnif» — o'quvchi darsni ochmasdan
  /// qanday savollar borligini ko'radi. Tasnif bo'lmasa faqat mashq soni.
  static String mashqYozuvi(List<MashqElement> e) {
    final tasnif = e.where((x) => x.turkum).length;
    final oddiy = e.length - tasnif;
    if (e.isEmpty) return 'Nazariy dars — takror bilan';
    if (tasnif == 0) return '$oddiy ta mashq';
    if (oddiy == 0) return '$tasnif ta tasnif savoli';
    return '$oddiy ta mashq · $tasnif tasnif';
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
    // Bir xil tarjimali ikkinchi shakl olinmaydi — «urdilar» ikkita
    // arabchaga to'g'ri kelsa, «arabchasini top» savoli buziladi.
    final tarjimalar = <String>{};
    // Tasnif juftliklari (kalima → tur) — jadvallardan, dars oxirida qo'shiladi.
    final turkumJuft = <String, String>{};
    final turkumZiddiyat = <String>{};

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
        // Tasnif jadvali: katak ↔ ustun sarlavhasi («qaysi kalima noqis?»).
        // Faqat kitobning o'z jadvali — ustunlar sarlavhasi, kataklar so'z.
        // Bir dars ichidagi HAMMA jadvallar birga: bir kalima ikki turda
        // (masalan «لا تَضْرِبْنَ» — nafiy ham, nahiy ham) — tashlanadi.
        for (final (ar, uz) in turkumJadvali(b)) {
          final oldingi = turkumJuft[ar];
          if (oldingi != null && oldingi != uz) turkumZiddiyat.add(ar);
          turkumJuft.putIfAbsent(ar, () => uz);
        }
        // Oxirgi arabcha katak ↔ oxirgi o'zbekcha katak: vazn jadvalida
        // «misol ↔ ma'no», shakl jadvalida «arabcha ↔ shakl nomi».
        for (final q in b.qatorlar) {
          final ar = q.kataklar.where(_arabcha.hasMatch).toList();
          // O'zbekcha katak — lotin harfli bo'lsin: boblar jadvalidagi
          // bo'sh katak belgisi («———») ma'no emas, u variant bo'lmasin.
          final uz = q.kataklar
              .where((c) => _lotin.hasMatch(c) && !_arabcha.hasMatch(c))
              .toList();
          if (ar.isNotEmpty && uz.isNotEmpty) {
            qosh(ar.last.trim(), uz.last.trim());
          }
        }
        continue;
      }
      if (b.type == 'matn') {
        final matn = _apostrof(b.uz);
        // Paradigma bloki (14, 6 yoki 3 siyg'a) — bo'lim yoki dars
        // sarlavhasi bilan.
        final yorliq = oxirgiBolim ?? l.title;
        final p = paradigma(matn, yorliq);
        if (p != null) {
          for (final (shakl, nom) in p) {
            qosh(shakl, '$yorliq · $nom');
          }
          continue;
        }
        if (!_lotin.hasMatch(matn)) continue; // faqat arabcha, paradigma emas
        // «X aslida Y edi» — e'lol juftliklari.
        for (final m in _asl.allMatches(matn)) {
          qosh(m.group(1)!.trim(), 'aslida ${m.group(2)!.trim()} edi');
        }
        // «ARABCHA – yorliq» juftliklari; asos — shu blokdagi moziy yoki
        // sarlavhadagi fe'l. Asossiz «muzore'» yorlig'i ko'p fe'lga
        // to'g'ri keladi va savolni ikki javobli qilib qo'yadi.
        final topilgan = _hosila.allMatches(matn).toList();
        String? asos = sarlavhaAsos;
        for (final m in topilgan) {
          if (m.group(2) == 'moziy') asos = m.group(1)!.trim();
        }
        if (asos != null) {
          for (final m in topilgan) {
            final ar = m.group(1)!.trim();
            final yorliq = m.group(2)!;
            if (yorliq == 'moziy' || ar == asos) continue;
            qosh(ar, '$yorliq ($asos)');
          }
        }
        // «ARABCHA – tarjimasi, izohi» namunalari.
        for (final m in _tarjima.allMatches(matn)) {
          final ar = m.group(1)!.trim();
          var uz = m.group(2)!.trim();
          final izoh = m.group(3)?.trim() ?? '';
          if (uz.length < 3 ||
              uz.length > 60 ||
              _arabcha.hasMatch(uz) ||
              _tarjimaEmas(uz)) {
            continue;
          }
          if (izoh.isNotEmpty &&
              izoh.length <= 30 &&
              !_arabcha.hasMatch(izoh) &&
              !_apostrof(izoh).toLowerCase().startsWith("siyg'a")) {
            uz = '$uz, $izoh';
          }
          if (tarjimalar.add(uz)) qosh(ar, uz);
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
    // Tasnif elementlari — o'z guruhi bilan: chalg'ituvchilar faqat shu
    // guruhdan olinadi (boshqa dars so'zi ham «noqis» bo'lishi mumkin).
    for (final e in turkumJuft.entries) {
      if (turkumZiddiyat.contains(e.key)) continue;
      if (!_yaroqli(e.key, e.value)) continue;
      natija.add(
        MashqElement(
          kalit: 'sarf::${l.num}::tur::${e.key}',
          ar: e.key,
          uz: e.value,
          darsId: l.completionId,
          tartib: l.num,
          modul: 'Sarf',
          ovoz: '',
          turkum: true,
          guruh: 'sarf-${l.num}',
        ),
      );
    }
    return natija;
  }

  /// Boblar jadvali (3-dars) ustunlari — kitobning IV–X darslari
  /// sarlavhalari bilan bir xil tartibda: Sahih, Muzo'af, Misol, Ajvaf,
  /// Noqis, Lafif, Multaviy. Kalit — jadvaldagi ustun sarlavhasi (aynan),
  /// qiymat — kitobdagi bob nomi. Sarlavha mos kelmasa ustun O'TKAZIB
  /// YUBORILADI — taxmin yo'q.
  static const Map<String, String> _bobTurlari = {
    'السَّالِمُ': 'Sahih',
    'الْمُضَعَّفُ': "Muzo'af",
    'الْمُعْتَلُّ الفَاء': 'Misol',
    'الْمُعْتَلُّ العَيْنُ': 'Ajvaf',
    'الْمُعْتَلّ اللاَّم': 'Noqis',
    'اللَّفِيفُ الْمَقْرُونُ': 'Lafif',
    'الْمَفْرُوق اللَّفِيفُ': 'Multaviy',
  };

  /// Jadvaldan tasnif juftliklari: (kalima, tur nomi).
  ///
  /// Ikki xil jadval: (1) boblar jadvali — arabcha ustun sarlavhalari,
  /// tur nomi [_bobTurlari] dan; (2) shakllar jadvali (36-dars) —
  /// o'zbekcha ustun sarlavhalari («Ismi foil»…), tur nomi sarlavhaning
  /// o'zi. Bo'sh («———») kataklar tashlanadi; «موزيي – مضارع» kabi
  /// juft katakdan faqat birinchi so'z olinadi. Bir kalima ikki xil
  /// turda uchrasa — ikkalasi ham tashlanadi (ikki to'g'ri javob bo'lmasin).
  static List<(String, String)> turkumJadvali(SarfBlock b) {
    if (b.ustunlar.isEmpty) return const [];
    // Tasnif jadvalida KATAKLAR faqat arabcha. Bironta o'zbekcha katak
    // bo'lsa (vazn/misol/ma'no jadvali) — bu tasnif emas, o'tkazib
    // yuboriladi: «فِعْلٌ ↔ Vaznlar» kabi soxta juftlik chiqmasin.
    for (final q in b.qatorlar) {
      if (q.kataklar.any(_lotin.hasMatch)) return const [];
    }
    final turlar = <String?>[];
    for (final u in b.ustunlar) {
      final ar = u.ar.trim();
      if (_arabcha.hasMatch(ar)) {
        final nom = _bobTurlari[ar];
        turlar.add(nom == null ? null : '$nom · $ar ${u.ar2}'.trim());
      } else if (_lotin.hasMatch(ar)) {
        turlar.add(ar);
      } else {
        turlar.add(null);
      }
    }
    if (turlar.every((t) => t == null)) return const [];
    final topilgan = <String, String>{};
    final ziddiyat = <String>{};
    for (final q in b.qatorlar) {
      for (var i = 0; i < q.kataklar.length && i < turlar.length; i++) {
        final tur = turlar[i];
        if (tur == null) continue;
        var k = q.kataklar[i].trim();
        if (k.isEmpty || !_arabcha.hasMatch(k)) continue;
        // «ضَرَبَ – يَضْرِبُ» → faqat moziy.
        k = k.split(RegExp(r'\s+[–-]\s+')).first.trim();
        if (k.isEmpty) continue;
        final oldingi = topilgan[k];
        if (oldingi != null && oldingi != tur) ziddiyat.add(k);
        topilgan.putIfAbsent(k, () => tur);
      }
    }
    return [
      for (final e in topilgan.entries)
        if (!ziddiyat.contains(e.key)) (e.key, e.value),
    ];
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
        // Yolg'iz harfning ovoz klipi yo'q (TTS uni jim o'qiydi) — harf
        // NOMI bilan gapiriladi: «qāf» eshitilib, ق tanlanadi.
        ovoz: h.nameAr,
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

  /// Barcha tasnif elementlari (Sarf jadvallari + Nahv ro'yxatlari) —
  /// «Tasnif mashqi» uchun; har biri o'z guruhida qoladi.
  static List<MashqElement> tasniflar() => [
    for (final l in repo.nahvLessons) ...nahvTurkumlar(l),
    for (final l in repo.sarfLessons) ...sarfDars(l).where((e) => e.turkum),
  ];

  /// Berilgan kalitlarga mos elementlar (eslash vaqti kelganlar uchun).
  static List<MashqElement> kalitlarBoyicha(Set<String> kalitlar) =>
      hammasi().where((e) => kalitlar.contains(e.kalit)).toList();

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
