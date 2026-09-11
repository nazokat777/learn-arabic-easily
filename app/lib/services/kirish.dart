import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Saytga kirish kodi — sayt faqat kursdoshlar uchun.
///
/// Repo va sayt ochiq (bepul GitHub Pages private repo'da ishlamaydi),
/// shuning uchun «kim kirsin» degan savol ilovaning o'zida hal qilinadi:
/// kod `assets/content/kirish.json` da turadi, to'g'ri kiritilgach shu
/// brauzerda eslab qolinadi. Bu qat'iy himoya emas (kod build ichida),
/// lekin tasodifiy tashrif buyuruvchini to'xtatadi — maqsad shu.
///
/// Faqat saytda ishlaydi: telefonga o'rnatilgan ilova so'ramaydi —
/// uni o'rnatganning o'zi kursdosh.
class Kirish {
  Kirish._();

  static const _kalit = 'kirishKodi';

  /// Kontentdagi kod; bo'sh bo'lsa darvoza yo'q.
  static Future<String> kodniOqi() async {
    try {
      final d = json.decode(
        await rootBundle.loadString('assets/content/kirish.json'),
      );
      return ((d as Map)['kod'] as String? ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  /// Darvoza kerakmi: faqat saytda va kod qo'yilgan bo'lsa, hamda shu
  /// brauzerda hali to'g'ri kod kiritilmagan bo'lsa.
  static Future<bool> kerakmi(String kod) async {
    if (!kIsWeb || kod.isEmpty) return false;
    final p = await SharedPreferences.getInstance();
    return p.getString(_kalit) != kod;
  }

  static bool togrimi(String kiritilgan, String kod) =>
      kiritilgan.trim().toLowerCase() == kod.toLowerCase();

  static Future<void> eslabQol(String kod) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kalit, kod);
  }
}
