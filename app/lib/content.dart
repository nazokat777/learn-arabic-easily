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
class QiroatLesson {
  final int num;
  final String titleAr;
  final String reading;
  final List<QiroatVocab> vocab;

  const QiroatLesson({
    required this.num,
    required this.titleAr,
    required this.reading,
    required this.vocab,
  });

  factory QiroatLesson.fromJson(Map<String, dynamic> j) => QiroatLesson(
        num: j['num'],
        titleAr: j['titleAr'],
        reading: j['reading'],
        vocab: (j['vocab'] as List).map((e) => QiroatVocab.fromJson(e)).toList(),
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
