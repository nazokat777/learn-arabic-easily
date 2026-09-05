import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
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
///   2. Ilova ochilgach, orqa fonda `version.json` tekshiriladi. Saytdagi
///      raqam kattaroq bo'lsa, fayllar yuklab olinadi va saqlanadi.
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

  /// Hozir ishlatilayotgan kontent versiyasi.
  Future<int> currentVersion() async {
    try {
      return (json.decode(await read('version.json'))['version'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  /// Saytdagi versiyani tekshiradi, yangisi bo'lsa yuklab oladi.
  ///
  /// Yangilanish bo'lsa `true` qaytaradi (keyingi ochilishda ko'rinadi).
  /// Internet yo'q bo'lsa jimgina `false` qaytaradi — bu xato emas.
  Future<bool> checkForUpdate() async {
    final d = await _cacheDir();
    if (d == null) return false;
    try {
      final head = await http
          .get(Uri.parse('$baseUrl/version.json'))
          .timeout(const Duration(seconds: 10));
      if (head.statusCode != 200) return false;
      final remote =
          (json.decode(utf8.decode(head.bodyBytes))['version'] as num).toInt();
      if (remote <= await currentVersion()) return false;

      // Avval hammasini yuklab olamiz, keyin yozamiz: yarim yangilangan
      // holat qolmasin (masalan yangi darslar, eski lug'at).
      final fetched = <String, String>{};
      for (final name in files) {
        final r = await http
            .get(Uri.parse('$baseUrl/$name'))
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
      await File('${d.path}/version.json')
          .writeAsString(utf8.decode(head.bodyBytes));
      return true;
    } catch (_) {
      return false;
    }
  }
}
