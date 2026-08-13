import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Arabcha talaffuz uchun audio xizmati (matndan-nutqqa).
/// Brauzer (web) va mobil qurilma TTS'idan foydalanadi — audio fayllar shart emas.
/// Arabcha ovoz bo'lmasa, jimgina o'chib qoladi (ilova buzilmaydi).
class Tts {
  Tts._();
  static final Tts instance = Tts._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _available = true;

  /// Hozir nimadir o'qilyaptimi (UI holati uchun).
  final ValueNotifier<String?> speakingId = ValueNotifier(null);

  bool get available => _available;

  Future<void> _ensure() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(kIsWeb ? 0.9 : 0.42); // sekinroq — o'rganish uchun
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(() => speakingId.value = null);
      _tts.setCancelHandler(() => speakingId.value = null);
      _tts.setErrorHandler((_) => speakingId.value = null);
    } catch (_) {
      _available = false;
    }
    _ready = true;
  }

  /// Ilova ishga tushganda chaqiriladi — sozlashni oldindan bajarib qo'yadi.
  ///
  /// Bu muhim: telefon brauzerlari ovozni faqat foydalanuvchi bosgan paytda
  /// ruxsat beradi. Agar tugma bosilganda oldin `await` qilsak, o'sha «bosish
  /// oynasi» yopilib, ovoz jimgina bloklanadi. Shuning uchun sozlash oldindan
  /// bajariladi va [speak] hech narsa kutmasdan darrov gapiradi.
  Future<void> init() => _ensure();

  /// Arabcha matnni o'qiydi. [id] — UI'da qaysi element «o'qilyapti»ni ko'rsatish uchun.
  Future<void> speak(String text, {String? id}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    if (!_ready) await _ensure(); // odatda init() tufayli bu yerga tushmaydi
    if (!_available) return;
    speakingId.value = id ?? clean;
    try {
      // stop() ni KUTMAYMIZ: bosish oynasidan chiqib ketmaslik uchun.
      // Web Speech API'da cancel() darhol bajariladi.
      unawaited(_tts.stop());
      await _tts.speak(clean);
    } catch (_) {
      speakingId.value = null;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    speakingId.value = null;
  }
}
