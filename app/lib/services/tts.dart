import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'vocab_audio.dart';

/// Arabcha talaffuz uchun audio xizmati (matndan-nutqqa).
/// Brauzer (web) va mobil qurilma TTS'idan foydalanadi — audio fayllar shart emas.
/// Arabcha ovoz bo'lmasa, jimgina o'chib qoladi (ilova buzilmaydi).
class Tts {
  Tts._();
  static final Tts instance = Tts._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  StreamSubscription<void>? _audioSub;
  bool _available = true;

  /// Hozir nimadir o'qilyaptimi (UI holati uchun).
  final ValueNotifier<String?> speakingId = ValueNotifier(null);

  /// Qurilmada ARABCHA ovoz bormi. `null` — hali aniqlanmagan.
  ///
  /// Bu `available` dan boshqa narsa: ovoz tizimi ishlayotgan bo'lishi mumkin,
  /// lekin arabcha ovoz paketi o'rnatilmagan bo'lsa, `speak()` jimgina hech
  /// narsa qilmaydi. Shuni oldindan bilib, foydalanuvchiga tushuntiramiz.
  final ValueNotifier<bool?> arabicAvailable = ValueNotifier(null);

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
    if (_available) unawaited(_detectArabic());
  }

  /// Qurilmada arabcha ovoz bor-yo'qligini aniqlaydi.
  ///
  /// Avval `getLanguages` ro'yxatidan `ar` bilan boshlanadiganini qidiramiz —
  /// bu eng ishonchlisi. Ro'yxat bo'sh chiqsa (ba'zi platformalarda shunday),
  /// `isLanguageAvailable` ga tushamiz. Ikkalasi ham javob bermasa, `true` deb
  /// hisoblaymiz: noaniqlik tufayli ishlaydigan ovozni o'chirib qo'ymaslik uchun.
  Future<void> _detectArabic() async {
    try {
      final langs = await _tts.getLanguages;
      if (langs is List && langs.isNotEmpty) {
        arabicAvailable.value = langs.any(
            (l) => l.toString().toLowerCase().startsWith('ar'));
        return;
      }
    } catch (_) {/* pastdagi usulga o'tamiz */}
    try {
      final ok = await _tts.isLanguageAvailable('ar-SA');
      arabicAvailable.value = ok == true;
    } catch (_) {
      arabicAvailable.value = true;
    }
  }

  /// Ilova ishga tushganda chaqiriladi — sozlashni oldindan bajarib qo'yadi.
  ///
  /// Bu muhim: telefon brauzerlari ovozni faqat foydalanuvchi bosgan paytda
  /// ruxsat beradi. Agar tugma bosilganda oldin `await` qilsak, o'sha «bosish
  /// oynasi» yopilib, ovoz jimgina bloklanadi. Shuning uchun sozlash oldindan
  /// bajariladi va [speak] hech narsa kutmasdan darrov gapiradi.
  Future<void> init() => _ensure();

  /// Arabcha matnni o'qiydi. [id] — UI'da qaysi element «o'qilyapti»ni ko'rsatish uchun.
  ///
  /// Avval TAYYOR OVOZ FAYLI qidiriladi — lug'at so'zlari ham, o'qish matnining
  /// jumlalari ham fayl bilan keladi. Topilsa o'sha ijro etiladi, ya'ni telefonda
  /// arabcha TTS ovozi bo'lmasa ham eshitiladi. Topilmasa (masalan foydalanuvchi
  /// bosgan alohida so'z) qurilma TTS'iga o'tamiz.
  Future<void> speak(String text, {String? id}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    if (VocabAudio.instance.has(clean)) {
      speakingId.value = id ?? clean;
      unawaited(_tts.stop());
      final played = await VocabAudio.instance.play(clean);
      if (played) {
        _audioSub?.cancel();
        _audioSub = VocabAudio.instance.onComplete.listen((_) {
          if (speakingId.value == (id ?? clean)) speakingId.value = null;
        });
        return;
      }
      speakingId.value = null; // ijro bo'lmadi — TTS'ga qaytamiz
    }

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
    _audioSub?.cancel();
    _audioSub = null;
    await VocabAudio.instance.stop();
    try {
      await _tts.stop();
    } catch (_) {}
    speakingId.value = null;
  }
}
