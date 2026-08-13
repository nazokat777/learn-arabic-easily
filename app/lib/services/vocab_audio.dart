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
  Map<String, String> _manifest = const {};
  bool _loaded = false;

  /// Ovozi bor so'zlar soni (0 — hali yuklanmagan yoki yo'q).
  int get count => _manifest.length;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await rootBundle.loadString('assets/audio/vocab_manifest.json');
      _manifest = (json.decode(raw) as Map).cast<String, String>();
    } catch (_) {
      _manifest = const {}; // ovoz fayllari qo'shilmagan — TTS'ga qaytamiz
    }
  }

  /// Shu so'zning tayyor ovozi bormi.
  bool has(String word) => _manifest.containsKey(word.trim());

  /// Tayyor ovozni ijro etadi. Fayl topilmasa yoki xato bo'lsa `false`
  /// qaytaradi — chaqiruvchi qurilma TTS'iga o'tishi mumkin.
  Future<bool> play(String word) async {
    final name = _manifest[word.trim()];
    if (name == null) return false;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/vocab/$name'));
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
