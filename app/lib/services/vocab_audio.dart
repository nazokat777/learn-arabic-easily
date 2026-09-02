import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Lug'at so'zlarining oldindan tayyorlangan ovozi.
///
/// Nega kerak: ilova avval faqat telefonning o'z TTS ovozidan foydalanardi,
/// lekin ko'p Android telefonlarda arabcha ovoz paketi umuman o'rnatilmagan
/// bo'ladi — o'shanda tugma bosilsa ham hech narsa eshitilmasdi.
///
/// Fayllar `ar-SA-HamedNeural` bilan tayyorlangan (`.qiroat_render/gen_vocab_audio.py`),
/// jimlik kesilgan va 32 kbps mono qilingan — bittasi ~3.7 KB. Flutter web
/// ularni faqat kerak bo'lganda yuklaydi, ya'ni ilova og'irlashmaydi.
class VocabAudio {
  VocabAudio._();
  static final VocabAudio instance = VocabAudio._();

  final AudioPlayer _player = AudioPlayer();

  /// Ovoz fayllari saytda turadi, ilova ichida emas.
  ///
  /// Sabab: kliplar 257 MB - APK ichiga sig'maydi. Ro'yxatlar (~1 MB) ilova
  /// bilan keladi, fayllar esa shu manzildan yuklanadi. Web ham xuddi shu
  /// manzildan oladi (o'zining sayti), shuning uchun ikkala platformada
  /// bitta yo'l ishlaydi.
  static const String baseUrl =
      'https://nazokat777.github.io/learn-arabic-easily/audio';

  /// Klip manzillariga qo'shiladigan versiya belgisi.
  ///
  /// Fayl NOMLARI qayta yasalganda o'zgarmaydi (s0001.mp3 o'sha-o'sha),
  /// shuning uchun brauzer/telefon keshi eski ovozni qaytaraverishi mumkin.
  /// Ovoz bazasi qayta yasalganda shu raqam oshiriladi - manzil o'zgargani
  /// uchun kesh chetlab o'tiladi. Oshirish esdan chiqmasligi uchun:
  /// ovoz commit'ida version.json bilan birga tekshiriladi.
  static const int audioVersion = 2;

  /// Matn → fayl yo'li («vocab/0001.mp3»). Barcha to'plamlar shu yerda:
  /// lug'at, matn jumlalari, so'zlar, alifbo va qo'shimchalar.
  Map<String, String> _manifest = const {};
  bool _loaded = false;

  /// Ovozi bor yozuvlar soni (0 — hali yuklanmagan yoki yo'q).
  int get count => _manifest.length;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final all = <String, String>{};
    for (final entry in const {
      'assets/audio/vocab_manifest.json': 'vocab',
      'assets/audio/sentence_manifest.json': 'sentences',
      'assets/audio/word_manifest.json': 'words',
      'assets/audio/alifbo_manifest.json': 'alifbo',
      'assets/audio/extra_manifest.json': 'extra',
    }.entries) {
      try {
        final raw = await rootBundle.loadString(entry.key);
        (json.decode(raw) as Map).forEach((k, v) {
          all['$k'] = '${entry.value}/$v';
        });
      } catch (_) {
        // bu to'plam qo'shilmagan — qolganlari baribir ishlaydi
      }
    }
    _manifest = all;
  }

  /// Shu matnning tayyor ovozi bormi.
  bool has(String text) => _manifest.containsKey(text.trim());

  /// Tayyor ovozni ijro etadi. Fayl topilmasa yoki xato bo'lsa `false`
  /// qaytaradi — chaqiruvchi qurilma TTS'iga o'tishi mumkin.
  Future<bool> play(String text) async {
    final path = _manifest[text.trim()];
    if (path == null) return false;
    try {
      await _player.stop();
      await _player.play(UrlSource('$baseUrl/$path?v=$audioVersion'));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Ijro tugaganda xabar beradi (UI holatini tozalash uchun).
  Stream<void> get onComplete => _player.onPlayerComplete;
}
