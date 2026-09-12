import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

/// Mukofot tovushlari — fayl emas, dasturda sintez qilinadi.
///
/// Nega tovush: harakatdan keyin 100 ms ichida kelgan qisqa tovush miya
/// uchun «bo'ldi» belgisi — ko'z bilan ko'rilgan yashil rangdan kuchliroq
/// va tezroq bog'lanadi (ko'p sezgili mukofot). Nega sintez: ilovaga
/// tovush fayli yuklab yurmaymiz; har tovush — sinus to'lqin, so'nuvchi
/// ovoz, 44 baytlik WAV sarlavhasi. Hajmi bir necha KB, kutish yo'q.
///
/// Tovushlar bir-biridan FARQ qiladi va daraja bilan o'sadi: oddiy
/// to'g'ri — ikki nota; kombo — uch nota ko'tariladi; sandiq va daraja —
/// to'rt notali arpejio. Xato — bitta past, yumshoq nota (jazo emas,
/// «hm» degan ohang).
class Tovush {
  Tovush._();

  static final AudioPlayer _p = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static bool yoqilgan = true;

  /// UI uchun: tugma holatini kuzatadi (yoqilgan/o'chiq).
  static final ValueNotifier<bool> holat = ValueNotifier(true);
  static const _kalit = 'tovush';

  /// Saqlangan tanlovni o'qiydi (ilova ishga tushganda).
  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      yoqilgan = p.getBool(_kalit) ?? true;
      holat.value = yoqilgan;
    } catch (_) {}
  }

  /// Tovushni yoqadi/o'chiradi va saqlaydi — o'quvchi o'zi hal qilsin
  /// (jamoat joyida, tunda). Ovozli darslar (TTS, kliplar) bunga bog'liq emas.
  static Future<void> almashtir() async {
    yoqilgan = !yoqilgan;
    holat.value = yoqilgan;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kalit, yoqilgan);
    } catch (_) {}
  }

  static const _hz = 22050;

  /// Notalar: (chastota Hz, davomiylik ms). Har nota eksponensial so'nadi.
  static Uint8List _wav(List<(double, int)> notalar, {double kuch = 0.32}) {
    final namunalar = <double>[];
    for (final (f, ms) in notalar) {
      final n = _hz * ms ~/ 1000;
      for (var i = 0; i < n; i++) {
        final t = i / _hz;
        final sonish = exp(-t * 9); // ~110 ms da yarmiga
        // Asosiy ton + zaif ikkinchi garmonika — «shisha» ohangi.
        final v =
            (sin(2 * pi * f * t) + 0.35 * sin(2 * pi * f * 2 * t)) * sonish;
        namunalar.add(v);
      }
    }
    final b = ByteData(44 + namunalar.length * 2);
    void yoz(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        b.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    final maLen = namunalar.length * 2;
    yoz(0, 'RIFF');
    b.setUint32(4, 36 + maLen, Endian.little);
    yoz(8, 'WAVE');
    yoz(12, 'fmt ');
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little); // PCM
    b.setUint16(22, 1, Endian.little); // mono
    b.setUint32(24, _hz, Endian.little);
    b.setUint32(28, _hz * 2, Endian.little);
    b.setUint16(32, 2, Endian.little);
    b.setUint16(34, 16, Endian.little);
    yoz(36, 'data');
    b.setUint32(40, maLen, Endian.little);
    for (var i = 0; i < namunalar.length; i++) {
      final v = (namunalar[i] * kuch).clamp(-1.0, 1.0);
      b.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return b.buffer.asUint8List();
  }

  // Notalar (Hz): C5 523, E5 659, G5 784, A5 880, C6 1047, E6 1319, G6 1568.
  static final Uint8List _togri = _wav([(880, 80), (1175, 140)]);
  static final Uint8List _kombo = _wav([(784, 70), (988, 70), (1319, 170)]);
  static final Uint8List _katta = _wav([
    (523, 70),
    (659, 70),
    (784, 70),
    (1047, 240),
  ]);
  static final Uint8List _xato = _wav([(220, 170)], kuch: 0.22);
  static final Uint8List _sandiq = _wav([
    (659, 60),
    (784, 60),
    (1047, 60),
    (1319, 60),
    (1568, 260),
  ]);
  static final Uint8List _bekat = _wav([(1047, 90), (1319, 200)]);

  static Future<void> _chal(Uint8List b) async {
    if (!yoqilgan) return;
    try {
      await _p.stop();
      await _p.play(BytesSource(b));
    } catch (_) {
      // Platforma bayt manbasini qo'llamasa — jim; mashq to'xtamaydi.
    }
  }

  /// To'g'ri javob — seriya darajasiga qarab boyroq.
  static Future<void> togri(int ketmaKet) =>
      _chal(ketmaKet >= 10 ? _katta : (ketmaKet >= 3 ? _kombo : _togri));

  static Future<void> xato() => _chal(_xato);
  static Future<void> sandiq() => _chal(_sandiq);
  static Future<void> daraja() => _chal(_katta);
  static Future<void> bekat() => _chal(_bekat);
}
