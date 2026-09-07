import 'dart:convert';
import 'services/content_updater.dart';

/// Bitta arab harfi (махраж va holatlari bilan).
class Letter {
  final int id;
  final String ar; // asosiy shakl
  final String nameUz;
  final String nameAr;
  final String translit;
  final String makhrajUz;
  final bool connectsLeft; // chapdagi harfga ulanadimi

  const Letter({
    required this.id,
    required this.ar,
    required this.nameUz,
    required this.nameAr,
    required this.translit,
    required this.makhrajUz,
    required this.connectsLeft,
  });

  factory Letter.fromJson(Map<String, dynamic> j) => Letter(
    id: j['id'],
    ar: j['ar'],
    nameUz: j['name_uz'],
    nameAr: j['name_ar'],
    translit: j['translit'],
    makhrajUz: j['makhraj_uz'],
    connectsLeft: j['connectsLeft'] ?? true,
  );

  /// Tatweel (kashida) — ulanish chizig'i, U+0640.
  ///
  /// Nega ZWJ emas: avval ko'rinmas ZWJ (U+200D) ishlatilardi va ilovada
  /// harf BOSHLANG'ICH shakl o'rniga ALOHIDA shaklda chizilardi — «جـ»
  /// o'rniga «ج». Ko'rinmas belgi shaper va matn yo'nalishiga bog'liq
  /// bo'lib qoldi.
  ///
  /// Tatweel — haqiqiy, ko'rinadigan ulovchi belgi. Arab darsliklarida
  /// harf shakllari aynan shu bilan bosiladi va u o'quvchiga qaysi tomon
  /// ulanishini KO'RSATIB ham turadi.
  static const tatweel = 'ـ';

  /// Harf holatlari — shakl tatweel bilan majburlanadi.
  ///
  /// Chapga ulanmaydigan harflarda (ا د ذ ر ز و) o'ngdagi tatweel
  /// qo'yilmaydi: ular o'zidan keyingisiga bog'lanmaydi, aks holda
  /// mavjud bo'lmagan shakl ko'rsatilardi.
  String get isolated => ar;
  String get initial => connectsLeft ? '$ar$tatweel' : ar;
  String get medial => connectsLeft ? '$tatweel$ar$tatweel' : '$tatweel$ar';
  String get finalForm => '$tatweel$ar';
}

/// Harakat yoki belgi.
class Haraka {
  final int id;
  final String nameUz;
  final String nameAr;
  final String sign;
  final String exampleAr;
  final String soundUz;
  final String descUz;

  const Haraka({
    required this.id,
    required this.nameUz,
    required this.nameAr,
    required this.sign,
    required this.exampleAr,
    required this.soundUz,
    required this.descUz,
  });

  factory Haraka.fromJson(Map<String, dynamic> j) => Haraka(
    id: j['id'],
    nameUz: j['name_uz'],
    nameAr: j['name_ar'],
    sign: j['sign'],
    exampleAr: j['example_ar'],
    soundUz: j['sound_uz'],
    descUz: j['desc_uz'],
  );
}

/// Lug'at so'zi.
class VocabWord {
  final int id;
  final String ar;
  final String uz;
  final int lesson;

  const VocabWord({
    required this.id,
    required this.ar,
    required this.uz,
    required this.lesson,
  });

  factory VocabWord.fromJson(Map<String, dynamic> j) =>
      VocabWord(id: j['id'], ar: j['ar'], uz: j['uz'], lesson: j['lesson']);
}

/// Mabdaul qiroat darsidagi bitta lug'at so'zi (arabcha + ko'plik + o'zbekcha).
class QiroatVocab {
  final String ar;
  final String pl; // ko'plik shakli (bo'lmasa bo'sh)
  final String uz;

  const QiroatVocab({required this.ar, required this.pl, required this.uz});

  factory QiroatVocab.fromJson(Map<String, dynamic> j) =>
      QiroatVocab(ar: j['ar'], pl: j['pl'] ?? '', uz: j['uz']);
}

/// «Mabdaul qiroat» kitobining bitta darsi: o'qish matni + lug'at.
/// Darsdagi grammatika jadvali (masalan zamirlar va o'tgan zamon fe'li).
///
/// Kitobda bu jadvallar dars matnidan keyin keladi va lug'atga kirmaydi -
/// shuning uchun ular ilovaga uzoq vaqt umuman tushmagan edi.
class QiroatTable {
  final String title;
  final String titleAr;
  final List<String> columns;
  final List<QiroatTableRow> rows;

  /// «pairs» — kataklar (arabcha, ma'nosi) juftligi bo'lib keladi (zamirlar
  /// jadvallari). «grid» — har bir katak alohida shakl bo'lib, ustun sarlavhasi
  /// bilan ko'rsatiladi (fe'l boblari jadvali).
  final String layout;

  const QiroatTable({
    required this.title,
    required this.titleAr,
    required this.columns,
    required this.rows,
    this.layout = 'pairs',
  });

  factory QiroatTable.fromJson(Map<String, dynamic> j) => QiroatTable(
    title: j['title'] ?? '',
    titleAr: j['titleAr'] ?? '',
    columns: (j['columns'] as List).cast<String>(),
    rows: (j['rows'] as List)
        .map((e) => QiroatTableRow.fromJson(e as Map<String, dynamic>))
        .toList(),
    layout: j['layout'] ?? 'pairs',
  );
}

/// Jadvalning bitta qatori. [group] - qatorlar bo'linadigan bo'lim
/// (III-shaxs, II-shaxs, I-shaxs), kitobdagi chekka ustunga mos keladi.
class QiroatTableRow {
  final String group;
  final List<String> cells;

  /// Qator yorlig'i — fe'l boblari jadvalidagi «БОБ» ustuni (I, II, IV ...).
  final String label;

  const QiroatTableRow({
    required this.group,
    required this.cells,
    this.label = '',
  });

  factory QiroatTableRow.fromJson(Map<String, dynamic> j) => QiroatTableRow(
    group: j['group'] ?? '',
    cells: (j['cells'] as List).cast<String>(),
    label: j['label'] ?? '',
  );
}

/// Nahv darsining ikki tilli bo'lagi: arabchasi kitobdan, o'zbekchasi tarjima.
class NahvPair {
  final String ar;
  final String uz;
  const NahvPair({required this.ar, required this.uz});

  factory NahvPair.fromJson(Map<String, dynamic> j) =>
      NahvPair(ar: j['ar'] ?? '', uz: j['uz'] ?? '');
}

/// Darsning bir bloki: izoh xatboshisi («para») yoki raqamli ro'yxat («list»).
class NahvBlock {
  final String type;
  final NahvPair? main; // para uchun
  final NahvPair? intro; // list uchun kirish jumlasi
  final List<NahvPair> items;

  const NahvBlock({
    required this.type,
    this.main,
    this.intro,
    this.items = const [],
  });

  factory NahvBlock.fromJson(Map<String, dynamic> j) {
    final type = j['type'] ?? 'para';
    return NahvBlock(
      type: type,
      main: type == 'list' ? null : NahvPair.fromJson(j),
      intro: j['intro'] == null
          ? null
          : NahvPair.fromJson(j['intro'] as Map<String, dynamic>),
      items: ((j['items'] as List?) ?? const [])
          .map((e) => NahvPair.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// «الدروس النحوية» kitobining bir darsi.
class NahvLesson {
  final int book;
  final int num;
  final int page; // manba kitobdagi sahifa - tekshirish uchun
  final String titleAr;
  final String title;
  final NahvPair rule;
  final List<NahvBlock> blocks;

  /// Kitobdagi «تَمْرِينٌ» - dars oxiridagi mashq savollari.
  /// Ba'zi darslarda yo'q, shuning uchun bo'sh bo'lishi mumkin.
  final List<NahvPair> exercise;

  /// Kitobdagi jadvallar (masalan zamirlar jadvali).
  final List<QiroatTable> tables;

  const NahvLesson({
    required this.book,
    required this.num,
    required this.page,
    required this.titleAr,
    required this.title,
    required this.rule,
    required this.blocks,
    this.exercise = const [],
    this.tables = const [],
  });

  factory NahvLesson.fromJson(Map<String, dynamic> j) => NahvLesson(
    book: j['book'] ?? 1,
    num: j['num'],
    page: j['page'] ?? 0,
    titleAr: j['titleAr'] ?? '',
    title: j['title'] ?? '',
    rule: j['rule'] == null
        ? const NahvPair(ar: '', uz: '')
        : NahvPair.fromJson(j['rule'] as Map<String, dynamic>),
    blocks: ((j['blocks'] as List?) ?? const [])
        .map((e) => NahvBlock.fromJson(e as Map<String, dynamic>))
        .toList(),
    exercise: ((j['exercise'] as List?) ?? const [])
        .map((e) => NahvPair.fromJson(e as Map<String, dynamic>))
        .toList(),
    tables: ((j['tables'] as List?) ?? const [])
        .map((e) => QiroatTable.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class QiroatLesson {
  final int book; // qaysi kitob (1, 2, 3)
  final int num;
  final String titleAr;
  final String reading;
  final List<QiroatVocab> vocab;
  final List<QiroatTable> tables;

  /// O'qish matnining o'zbekcha tarjimasi (kitobning oxiridan, 1-kitob).
  /// Bo'sh bo'lishi mumkin - 2 va 3-kitobda tarjima bo'limi yo'q.
  final String translation;

  /// Darsdan keyingi mashq: o'zbekcha gaplarni arabchaga o'girish (1-kitob).
  final String exercise;

  /// Mashqning arabcha javobi - kitobda «N-дарснинг ўзбекча матнидаги
  /// таржима» sarlavhasi ostida beriladi. PDF matn qatlamida buzuq, shuning
  /// uchun sahifa tasviridan o'qib kiritiladi (bosqichma-bosqich).
  final String exerciseAnswer;

  const QiroatLesson({
    required this.book,
    required this.num,
    required this.titleAr,
    required this.reading,
    required this.vocab,
    this.tables = const [],
    this.translation = '',
    this.exercise = '',
    this.exerciseAnswer = '',
  });

  /// Dars tugatilganini belgilash uchun noyob id (kitob + dars).
  String get completionId => book == 1 ? 'qiroat_$num' : 'qiroat_b${book}_$num';

  factory QiroatLesson.fromJson(Map<String, dynamic> j) => QiroatLesson(
    book: j['book'] ?? 1,
    num: j['num'],
    titleAr: j['titleAr'],
    reading: j['reading'],
    vocab: (j['vocab'] as List).map((e) => QiroatVocab.fromJson(e)).toList(),
    tables: ((j['tables'] as List?) ?? const [])
        .map((e) => QiroatTable.fromJson(e as Map<String, dynamic>))
        .toList(),
    translation: j['translation'] ?? '',
    exercise: j['exercise'] ?? '',
    exerciseAnswer: j['exerciseAnswer'] ?? '',
  );
}

/// Barcha kontentni yuklaydigan repozitoriy.
///
/// Fayllar to'g'ridan-to'g'ri assets'dan emas, [ContentUpdater] orqali
/// o'qiladi: agar saytdan yangi darslar yuklab olingan bo'lsa, o'shalar
/// ishlatiladi; aks holda APK ichidagi nusxa.
/// «Harflarni ulash» darsining bitta so'zi.
class UlashWord {
  final String ar;
  final String uz;
  const UlashWord({required this.ar, required this.uz});

  factory UlashWord.fromJson(Map<String, dynamic> j) =>
      UlashWord(ar: j['ar'] ?? '', uz: j['uz'] ?? '');
}

/// Ulash darsining bir bosqichi — oddiydan murakkabgacha.
///
/// Bosqichlar arab yozuvini o'rgatishning klassik tartibida: avval
/// harflari chapga ulanmaydigan so'zlar (shakl o'zgarmaydi), keyin
/// aralash qisqa so'zlar, so'ng to'liq ulanadiganlari va uzunlari.
class UlashStage {
  final int num;
  final String title;
  final String titleAr;
  final String explain;
  final List<UlashWord> words;

  const UlashStage({
    required this.num,
    required this.title,
    required this.titleAr,
    required this.explain,
    required this.words,
  });

  factory UlashStage.fromJson(Map<String, dynamic> j) => UlashStage(
    num: j['num'] ?? 0,
    title: j['title'] ?? '',
    titleAr: j['titleAr'] ?? '',
    explain: j['explain'] ?? '',
    words: ((j['words'] as List?) ?? const [])
        .map((e) => UlashWord.fromJson(e))
        .toList(),
  );
}

/// «Mukammal sarf darsligi» kitobining bitta darsi.
///
/// Nahv kitoblaridan farqi: u yerda har blok arabcha jumla + tarjimasi
/// edi, bu kitobda esa asosiy matn O'ZBEKCHA, arabcha misollar gap ichida
/// keladi. Shuning uchun blok turlari boshqacha:
///   matn  — o'zbekcha xatboshi (arabcha misol ichida bo'lishi mumkin)
///   misol — alohida turgan arabcha satr (tinglash tugmasi bilan)
///   list  — raqamli ro'yxat, har band o'zbekcha matn
/// Sarf jadvalining bitta ustuni: nomi va kitobda qavs ichida berilgan
/// ikkinchi nomi (masalan «السَّالِمُ» va
/// «(الصَّحِيحُ)»).
class SarfUstun {
  final String ar;
  final String ar2;
  const SarfUstun({required this.ar, this.ar2 = ''});

  factory SarfUstun.fromJson(Map<String, dynamic> j) =>
      SarfUstun(ar: j['ar'] ?? '', ar2: j['ar2'] ?? '');
}

/// Jadvalning bitta qatori. [bolim] bo'sh bo'lmasa — bu qator emas,
/// bo'limni ajratib turuvchi sarlavha («ثلاثي مجرد» kabi).
class SarfQator {
  final String bolim;
  final String bob;
  final String raqam;
  final List<String> kataklar;

  const SarfQator({
    this.bolim = '',
    this.bob = '',
    this.raqam = '',
    this.kataklar = const [],
  });

  bool get bolimmi => bolim.isNotEmpty;

  factory SarfQator.fromJson(Map<String, dynamic> j) => SarfQator(
    bolim: j['bolim'] ?? '',
    bob: j['bob'] ?? '',
    raqam: j['raqam'] ?? '',
    kataklar: ((j['kataklar'] as List?) ?? const []).map((e) => '$e').toList(),
  );
}

class SarfBlock {
  final String type;
  final String uz;
  final String ar;
  final String intro;
  final List<String> items;

  /// «jadval» turi uchun: ustunlar sarlavhasi va qatorlar.
  final String sarlavha;
  final List<SarfUstun> ustunlar;
  final List<SarfQator> qatorlar;

  const SarfBlock({
    required this.type,
    this.uz = '',
    this.ar = '',
    this.intro = '',
    this.items = const [],
    this.sarlavha = '',
    this.ustunlar = const [],
    this.qatorlar = const [],
  });

  factory SarfBlock.fromJson(Map<String, dynamic> j) => SarfBlock(
    type: j['type'] ?? 'matn',
    uz: j['uz'] ?? '',
    ar: j['ar'] ?? '',
    intro: j['intro'] ?? '',
    items: ((j['items'] as List?) ?? const []).map((e) => '$e').toList(),
    sarlavha: j['sarlavha'] ?? '',
    ustunlar: ((j['ustunlar'] as List?) ?? const [])
        .map((e) => SarfUstun.fromJson(e as Map<String, dynamic>))
        .toList(),
    qatorlar: ((j['qatorlar'] as List?) ?? const [])
        .map((e) => SarfQator.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class SarfLesson {
  final int num;
  final int page; // manba kitobdagi sahifa - tekshirish uchun
  final String titleAr;
  final String title;
  final List<SarfBlock> blocks;

  const SarfLesson({
    required this.num,
    required this.page,
    required this.titleAr,
    required this.title,
    required this.blocks,
  });

  factory SarfLesson.fromJson(Map<String, dynamic> j) => SarfLesson(
    num: j['num'],
    page: j['page'] ?? 0,
    titleAr: j['titleAr'] ?? '',
    title: j['title'] ?? '',
    blocks: ((j['blocks'] as List?) ?? const [])
        .map((e) => SarfBlock.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  String get completionId => 'sarf-$num';
}

class ContentRepository {
  List<Letter> letters = [];
  List<Haraka> harakat = [];
  List<VocabWord> words = [];
  List<QiroatLesson> qiroatLessons = [];
  List<NahvLesson> nahvLessons = [];
  List<UlashStage> ulashStages = [];

  /// Grammatika va bog'lovchi so'zlar — dars lug'atlarida yo'q, lekin
  /// matnda ko'p uchraydigan so'zlar (so'zga bosilganda kerak bo'ladi).
  List<QiroatVocab> grammatika = [];

  /// «Mukammal sarf darsligi» darslari.
  List<SarfLesson> sarfLessons = [];

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final l = json.decode(await ContentUpdater.instance.read('letters.json'));
    letters = (l['letters'] as List).map((e) => Letter.fromJson(e)).toList();

    final h = json.decode(await ContentUpdater.instance.read('harakat.json'));
    harakat = (h['harakat'] as List).map((e) => Haraka.fromJson(e)).toList();

    final v = json.decode(
      await ContentUpdater.instance.read('vocabulary.json'),
    );
    words = (v['words'] as List).map((e) => VocabWord.fromJson(e)).toList();

    final q = json.decode(
      await ContentUpdater.instance.read('qiroat_lessons.json'),
    );
    qiroatLessons = (q['lessons'] as List)
        .map((e) => QiroatLesson.fromJson(e))
        .toList();

    final n = json.decode(
      await ContentUpdater.instance.read('nahv_lessons.json'),
    );
    nahvLessons = (n['lessons'] as List)
        .map((e) => NahvLesson.fromJson(e))
        .toList();

    // Ulash darsi keyinroq qo'shilgan — eski APK'da fayl bo'lmasligi mumkin,
    // shuning uchun yo'qligi ilovani to'xtatmasin.
    try {
      final u = json.decode(await ContentUpdater.instance.read('ulash.json'));
      ulashStages = (u['stages'] as List)
          .map((e) => UlashStage.fromJson(e))
          .toList();
    } catch (_) {
      ulashStages = [];
    }

    // Grammatika lug'ati keyinroq qo'shilgan — eski APK'da fayl
    // bo'lmasligi mumkin, yo'qligi ilovani to'xtatmasin.
    try {
      final g = json.decode(
        await ContentUpdater.instance.read('grammatika.json'),
      );
      grammatika = (g['words'] as List)
          .map((e) => QiroatVocab.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      grammatika = [];
    }

    // Sarf keyinroq qo'shilgan — eski APK'da fayl bo'lmasligi mumkin.
    try {
      final sf = json.decode(
        await ContentUpdater.instance.read('sarf_lessons.json'),
      );
      sarfLessons = (sf['lessons'] as List)
          .map((e) => SarfLesson.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      sarfLessons = [];
    }

    _loaded = true;
  }
}
