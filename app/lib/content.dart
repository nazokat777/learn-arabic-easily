import 'dart:convert';
import 'package:flutter/services.dart';

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

  static const zwj = '‍'; // zero-width joiner

  /// Harf holatlari — ZWJ orqali shrift avtomatik to'g'ri shakl beradi.
  String get isolated => ar;
  String get initial => connectsLeft ? '$ar$zwj' : ar;
  String get medial => connectsLeft ? '$zwj$ar$zwj' : '$zwj$ar';
  String get finalForm => '$zwj$ar';
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

  factory VocabWord.fromJson(Map<String, dynamic> j) => VocabWord(
        id: j['id'],
        ar: j['ar'],
        uz: j['uz'],
        lesson: j['lesson'],
      );
}

/// Mabdaul qiroat darsidagi bitta lug'at so'zi (arabcha + ko'plik + o'zbekcha).
class QiroatVocab {
  final String ar;
  final String pl; // ko'plik shakli (bo'lmasa bo'sh)
  final String uz;

  const QiroatVocab({required this.ar, required this.pl, required this.uz});

  factory QiroatVocab.fromJson(Map<String, dynamic> j) => QiroatVocab(
        ar: j['ar'],
        pl: j['pl'] ?? '',
        uz: j['uz'],
      );
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

  const QiroatTable({
    required this.title,
    required this.titleAr,
    required this.columns,
    required this.rows,
  });

  factory QiroatTable.fromJson(Map<String, dynamic> j) => QiroatTable(
        title: j['title'] ?? '',
        titleAr: j['titleAr'] ?? '',
        columns: (j['columns'] as List).cast<String>(),
        rows: (j['rows'] as List)
            .map((e) => QiroatTableRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Jadvalning bitta qatori. [group] - qatorlar bo'linadigan bo'lim
/// (III-shaxs, II-shaxs, I-shaxs), kitobdagi chekka ustunga mos keladi.
class QiroatTableRow {
  final String group;
  final List<String> cells;
  const QiroatTableRow({required this.group, required this.cells});

  factory QiroatTableRow.fromJson(Map<String, dynamic> j) => QiroatTableRow(
        group: j['group'] ?? '',
        cells: (j['cells'] as List).cast<String>(),
      );
}

class QiroatLesson {
  final int book; // qaysi kitob (1, 2, 3)
  final int num;
  final String titleAr;
  final String reading;
  final List<QiroatVocab> vocab;
  final List<QiroatTable> tables;

  const QiroatLesson({
    required this.book,
    required this.num,
    required this.titleAr,
    required this.reading,
    required this.vocab,
    this.tables = const [],
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
      );
}

/// Barcha kontentni assets'dan yuklaydigan repozitoriy.
class ContentRepository {
  List<Letter> letters = [];
  List<Haraka> harakat = [];
  List<VocabWord> words = [];
  List<QiroatLesson> qiroatLessons = [];

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final l = json.decode(await rootBundle.loadString('assets/content/letters.json'));
    letters = (l['letters'] as List).map((e) => Letter.fromJson(e)).toList();

    final h = json.decode(await rootBundle.loadString('assets/content/harakat.json'));
    harakat = (h['harakat'] as List).map((e) => Haraka.fromJson(e)).toList();

    final v = json.decode(await rootBundle.loadString('assets/content/vocabulary.json'));
    words = (v['words'] as List).map((e) => VocabWord.fromJson(e)).toList();

    final q = json.decode(await rootBundle.loadString('assets/content/qiroat_lessons.json'));
    qiroatLessons = (q['lessons'] as List).map((e) => QiroatLesson.fromJson(e)).toList();

    _loaded = true;
  }
}
