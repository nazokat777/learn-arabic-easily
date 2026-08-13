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

  /// Matn → asset yo'li (`audio/vocab/0001.mp3` yoki `audio/sentences/s0001.mp3`).
  /// Lug'at so'zlari ham, o'qish matnining jumlalari ham shu yerda.
  Map<String, String> _manifest = const {};
  bool _loaded = false;

  /// Ovozi bor yozuvlar soni (0 — hali yuklanmagan yoki yo'q).
  int get count => _manifest.length;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final all = <String, String>{};
    for (final entry in const {
      'assets/audio/vocab_manifest.json': 'audio/vocab',
      'assets/audio/sentence_manifest.json': 'audio/sentences',
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
      await _player.play(AssetSource(path));
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
