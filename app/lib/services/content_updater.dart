import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Darslarni internetdan yangilab turadi ("over-the-air").
///
/// Nega kerak: APK telefonga bir marta o'rnatiladi. Yangi kitob yoki dars
/// qo'shilganda foydalanuvchi APK'ni qaytadan o'rnatishi shart bo'lmasin —
/// ilova ochilganda saytdagi versiyani tekshiradi va yangisini yuklab oladi.
///
/// Ishlash tartibi:
///   1. Kontent har doim shu joydan o'qiladi: avval YUKLANGAN nusxa
///      (telefon xotirasidagi papka), u yo'q bo'lsa — APK ichidagi nusxa.
///      Ya'ni internet bo'lmasa ham ilova to'liq ishlaydi.
///   2. Ilova HAR ochilganda orqa fonda `version.json` tekshiriladi.
///      Saytdagi raqam kattaroq BO'LSA YOKI kontentning barmoq izi
///      (`hash`) boshqacha bo'lsa, fayllar yuklab olinadi va saqlanadi.
///   3. Yangi kontent KEYINGI ochilishda kuchga kiradi — dars o'qib
///      turgan odamning ostidan matn almashib ketmasligi uchun.
///
/// Web'da bu umuman kerak emas: sayt o'zi har safar eng yangisini beradi.
class ContentUpdater {
  ContentUpdater._();
  static final ContentUpdater instance = ContentUpdater._();

  static const String baseUrl =
      'https://nazokat777.github.io/learn-arabic-easily/content';

  /// Yangilanadigan fayllar ro'yxati.
  static const List<String> files = [
    'letters.json',
    'harakat.json',
    'vocabulary.json',
    'qiroat_lessons.json',
    'nahv_lessons.json',
    'ulash.json',
    'grammatika.json',
    'sarf_lessons.json',
  ];

  Directory? _dir;

  Future<Directory?> _cacheDir() async {
    if (kIsWeb) return null;
    if (_dir != null) return _dir;
    try {
      final base = await getApplicationSupportDirectory();
      final d = Directory('${base.path}/content');
      if (!await d.exists()) await d.create(recursive: true);
      return _dir = d;
    } catch (_) {
      return null;
    }
  }

  /// Kontent faylini o'qiydi: yuklangan nusxa bo'lsa o'sha, bo'lmasa APK ichidagi.
  Future<String> read(String name) async {
    final d = await _cacheDir();
    if (d != null) {
      final f = File('${d.path}/$name');
      try {
        if (await f.exists()) {
          final s = await f.readAsString();
          // Buzuq fayl ilovani ishga tushirmay qo'yishi mumkin — tekshiramiz.
          json.decode(s);
          return s;
        }
      } catch (_) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
    return rootBundle.loadString('assets/content/$name');
  }

  /// Hozir ishlatilayotgan kontent versiyasi va barmoq izi.
  Future<({int version, String hash})> _joriy() async {
    try {
      final d = json.decode(await read('version.json')) as Map;
      return (
        version: (d['version'] as num?)?.toInt() ?? 0,
        hash: (d['hash'] as String?) ?? '',
      );
    } catch (_) {
      return (version: 0, hash: '');
    }
  }

  /// Hozir ishlatilayotgan kontent versiyasi.
  Future<int> currentVersion() async => (await _joriy()).version;

  /// Keshni chetlab o'tuvchi manzil.
  ///
  /// Nega kerak: GitHub Pages javoblarni bir necha daqiqa keshlashga
  /// ruxsat beradi va telefon eski `version.json` ni qaytaraverishi
  /// mumkin — o'shanda yangi darslar yetib bormaydi. Manzilga har safar
  /// boshqacha parametr qo'shilsa, kesh chetlab o'tiladi.
  @visibleForTesting
  Uri uriFor(String name) =>
      Uri.parse('$baseUrl/$name?t=${DateTime.now().millisecondsSinceEpoch}');

  static const Map<String, String> _noCache = {
    'Cache-Control': 'no-cache, no-store',
    'Pragma': 'no-cache',
  };

  /// Saytdagi versiyani tekshiradi, yangisi bo'lsa yuklab oladi.
  ///
  /// Yangilanish bo'lsa `true` qaytaradi (keyingi ochilishda ko'rinadi).
  /// Internet yo'q bo'lsa jimgina `false` qaytaradi — bu xato emas.
  Future<bool> checkForUpdate() async {
    final d = await _cacheDir();
    if (d == null) return false;
    try {
      final head = await http
          .get(uriFor('version.json'), headers: _noCache)
          .timeout(const Duration(seconds: 10));
      if (head.statusCode != 200) return false;
      final uzoq = json.decode(utf8.decode(head.bodyBytes)) as Map;
      final uzoqVersion = (uzoq['version'] as num?)?.toInt() ?? 0;
      final uzoqHash = (uzoq['hash'] as String?) ?? '';
      final joriy = await _joriy();

      // Raqam oshgan bo'lsa YOKI kontent izi boshqacha bo'lsa yuklaymiz.
      // Iz bo'yicha tekshiruv «versiyani oshirish esdan chiqdi» degan
      // xatoni butunlay yo'q qiladi.
      final yangilik =
          uzoqVersion > joriy.version ||
          (uzoqHash.isNotEmpty && uzoqHash != joriy.hash);
      if (!yangilik) return false;

      // Avval hammasini yuklab olamiz, keyin yozamiz: yarim yangilangan
      // holat qolmasin (masalan yangi darslar, eski lug'at).
      final fetched = <String, String>{};
      for (final name in files) {
        final r = await http
            .get(uriFor(name), headers: _noCache)
            .timeout(const Duration(seconds: 60));
        if (r.statusCode != 200) return false;
        final body = utf8.decode(r.bodyBytes);
        json.decode(body); // buzuq bo'lsa shu yerda to'xtaydi
        fetched[name] = body;
      }
      for (final e in fetched.entries) {
        await File('${d.path}/${e.key}').writeAsString(e.value);
      }
      // Versiyani ENG OXIRIDA yozamiz — yozish yarmida uzilib qolsa,
      // ilova eski versiyada qolib, keyingi safar yana urinadi.
      await File(
        '${d.path}/version.json',
      ).writeAsString(utf8.decode(head.bodyBytes));
      return true;
    } catch (_) {
      return false;
    }
  }
}
