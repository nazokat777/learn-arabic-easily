import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../arabic.dart';
import '../main.dart';
import '../services/content_updater.dart';
import '../mashq/element.dart';
import '../services/eslatma.dart';
import 'xarita.dart';

/// Kunlik vazifa turlari — «7 qadamli algoritm» tartibida.
///
/// 1. hajm    — ma'no va hajm: bugun NIMANI va NECHTASINI yodlaysiz.
/// 2. ilgak   — tovushga ilgak + obraz: har so'zga o'zingiz sahna to'qiysiz.
/// 3. eslash  — qaramasdan eslash (retrieval).
/// 4. teskari — ikkinchi tomon: o'zbekchadan arabchani o'zingiz yozasiz.
/// 5. takror  — oraliqli takrorlash (1-2-4-7-14-30 kun).
/// 6. qoida   — bugungi dars/qoidani o'qish.
/// 7. gap     — hayotda qo'llash: so'zni jumla ichida topish, gap tuzish.
enum Vazifa { hajm, ilgak, qoida, eslash, teskari, takror, gap }

/// Kitobni tanlangan muddatga bo'lgan reja.
class Reja {
  final String kitobId;

  /// Boshlangan kun (1970-yildan beri kunlar).
  final int boshKun;
  final int kunlar;

  /// Bajarilgan vazifalar: kun indeksi → vazifa nomlari.
  final Map<int, Set<String>> bajarilgan;

  Reja({
    required this.kitobId,
    required this.boshKun,
    required this.kunlar,
    Map<int, Set<String>>? bajarilgan,
  }) : bajarilgan = bajarilgan ?? {};

  KitobXarita? get kitob => KitobXarita.top(kitobId);

  /// Kitob turiga qarab kunlik vazifalar ro'yxati.
  List<Vazifa> get vazifalar => (kitob?.lugatKitobi ?? true)
      ? const [
          Vazifa.hajm,
          Vazifa.ilgak,
          Vazifa.eslash,
          Vazifa.teskari,
          Vazifa.takror,
          Vazifa.qoida,
          Vazifa.gap,
        ]
      : const [
          Vazifa.qoida,
          Vazifa.eslash,
          Vazifa.teskari,
          Vazifa.takror,
          Vazifa.gap,
        ];

  bool bajarildimi(int kun, Vazifa v) =>
      bajarilgan[kun]?.contains(v.name) ?? false;

  bool kunTugadimi(int kun) => vazifalar.every((v) => bajarildimi(kun, v));

  int get tugaganKunlar =>
      List.generate(kunlar, (i) => i).where(kunTugadimi).length;

  bool get tugadi => tugaganKunlar >= kunlar;

  /// Kalendar bo'yicha bugun rejaning nechanchi kuni (0 dan).
  int get kalendarKun => (Reja.bugun() - boshKun).clamp(0, kunlar - 1);

  /// Ishlanadigan kun — birinchi tugallanmagan kun. Kun qoldirilsa jazo
  /// yo'q: reja siljimaydi, qolgan joyingizdan davom etasiz.
  int get joriyKun {
    for (var i = 0; i < kunlar; i++) {
      if (!kunTugadimi(i)) return i;
    }
    return kunlar - 1;
  }

  /// Musbat — rejadan orqada (kun), manfiy — oldinda.
  int get orqada => (Reja.bugun() - boshKun).clamp(0, kunlar) - joriyKun;

  // ---------------- Kunlarga bo'lish ----------------

  List<MashqElement>? _hammaElement;

  /// Kitobning hamma yodlanadigan elementlari, dars tartibida.
  List<MashqElement> get hammaElement =>
      _hammaElement ??= [for (final d in kitob!.darslar) ...d.elementlar()];

  (int, int) _oraliq(int n, int kun) =>
      ((kun * n) ~/ kunlar, ((kun + 1) * n) ~/ kunlar);

  /// Shu kunning yangi so'zlari (lug'at kitobi) yoki darslarining
  /// misollari (qoida kitobi).
  List<MashqElement> kunElementlari(int kun) {
    final k = kitob;
    if (k == null) return const [];
    if (k.lugatKitobi) {
      final (a, b) = _oraliq(hammaElement.length, kun);
      return hammaElement.sublist(a, b);
    }
    return [for (final d in kunDarslari(kun)) ...d.elementlar()];
  }

  /// Shu kunda o'qiladigan darslar.
  List<DarsBirlik> kunDarslari(int kun) {
    final k = kitob;
    if (k == null) return const [];
    if (!k.lugatKitobi) {
      final (a, b) = _oraliq(k.darslar.length, kun);
      return k.darslar.sublist(a, b);
    }
    // Lug'at kitobi: so'zlari shu kunga tushgan darslar.
    final idlar = {for (final e in kunElementlari(kun)) e.darsId};
    return k.darslar.where((d) => idlar.contains(d.id)).toList();
  }

  /// Oldingi kunlarda o'tilgan va bugun eslash vaqti kelgan elementlar.
  List<MashqElement> takrorElementlari(int kun) {
    final vaqti = progress.eslashKerakKalitlar.toSet();
    final oldingi = <MashqElement>[];
    for (var i = 0; i < kun; i++) {
      oldingi.addAll(kunElementlari(i).where((e) => vaqti.contains(e.kalit)));
    }
    oldingi.sort((a, b) => b.zaiflik.compareTo(a.zaiflik));
    return oldingi;
  }

  /// Kalendar sanasi bo'yicha (UTC hisobida — mahalliy zonaning 1970-yilgi
  /// farqi yarim tunda kunni siljitmasin).
  static int bugun() {
    final n = DateTime.now();
    return DateTime.utc(n.year, n.month, n.day)
        .difference(DateTime.utc(1970))
        .inDays;
  }

  Map<String, dynamic> toJson() => {
    'k': kitobId,
    'b': boshKun,
    'n': kunlar,
    'd': {
      for (final e in bajarilgan.entries) '${e.key}': e.value.toList(),
    },
  };

  factory Reja.fromJson(Map<String, dynamic> j) => Reja(
    kitobId: j['k'] as String,
    boshKun: j['b'] as int,
    kunlar: j['n'] as int,
    bajarilgan: {
      for (final e in ((j['d'] as Map?) ?? {}).entries)
        int.parse(e.key as String): (e.value as List).cast<String>().toSet(),
    },
  );
}

/// Ilovaning tayyor mnemonik ilgagi: o'qilishi, tovushdosh tanish so'z,
/// sahna. Kitob matni EMAS — yodlash yordamchisi (ilgak.json).
class TayyorIlgak {
  final String oqilishi;
  final String ilgak;
  final String sahna;
  const TayyorIlgak(this.oqilishi, this.ilgak, this.sahna);
}

/// Rejalar, ilgaklar, zanjir va eslatma vaqtini saqlaydi.
class RejaXotira extends ChangeNotifier {
  RejaXotira._();
  static final instance = RejaXotira._();

  SharedPreferences? _p;
  final List<Reja> rejalar = [];

  /// So'z kaliti → o'quvchi o'zi to'qigan ilgak/sahna.
  final Map<String, String> ilgaklar = {};

  /// Tayyor ilgaklar: harakatsiz arabcha → ilgak.
  final Map<String, TayyorIlgak> _tayyor = {};

  TayyorIlgak? tayyorIlgak(String ar) {
    final k = stripDiacritics(splitForms(ar).first.split('=').first)
        .replaceAll('؟', '')
        .replaceAll('?', '')
        .trim();
    return _tayyor[k] ?? _tayyor['$k؟'];
  }

  Future<void> _tayyorYukla() async {
    try {
      final j =
          jsonDecode(await ContentUpdater.instance.read('ilgak.json')) as Map;
      _tayyor.clear();
      for (final e in (j['sozlar'] as Map).entries) {
        final v = e.value as Map;
        final k = (e.key as String).replaceAll('؟', '').trim();
        _tayyor[k] = TayyorIlgak(
          v['o'] as String,
          v['i'] as String,
          v['s'] as String,
        );
      }
    } catch (_) {}
  }

  /// Kamida bitta reja-kuni tugatilgan kalendar kunlari.
  final Set<int> _faolKunlar = {};

  /// Eslatma: kun ichidagi daqiqa (masalan 20:00 → 1200); null — o'chiq.
  int? eslatmaDaqiqa;

  /// Eslatma oxirgi marta ko'rsatilgan kun (kuniga bir marta).
  int _eslatildi = -1;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    rejalar
      ..clear()
      ..addAll(
        (_p!.getStringList('mnem_rejalar') ?? []).map(
          (s) => Reja.fromJson(jsonDecode(s) as Map<String, dynamic>),
        ),
      );
    rejalar.removeWhere((r) => r.kitob == null);
    final il = _p!.getString('mnem_ilgak');
    if (il != null) {
      ilgaklar
        ..clear()
        ..addAll((jsonDecode(il) as Map).cast<String, String>());
    }
    _faolKunlar
      ..clear()
      ..addAll((_p!.getStringList('mnem_faol') ?? []).map(int.parse));
    eslatmaDaqiqa = _p!.getInt('mnem_eslatma');
    await _tayyorYukla();
    _eslatildi = _p!.getInt('mnem_eslatildi') ?? -1;
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _p ??= await SharedPreferences.getInstance();
    await p.setStringList('mnem_rejalar', [
      for (final r in rejalar) jsonEncode(r.toJson()),
    ]);
    await p.setString('mnem_ilgak', jsonEncode(ilgaklar));
    await p.setStringList('mnem_faol', [
      for (final k in _faolKunlar) '$k',
    ]);
    final e = eslatmaDaqiqa;
    if (e == null) {
      await p.remove('mnem_eslatma');
    } else {
      await p.setInt('mnem_eslatma', e);
    }
    await p.setInt('mnem_eslatildi', _eslatildi);
    notifyListeners();
  }

  Reja? reja(String kitobId) {
    for (final r in rejalar) {
      if (r.kitobId == kitobId) return r;
    }
    return null;
  }

  Future<Reja> boshla(String kitobId, int kunlar) async {
    rejalar.removeWhere((r) => r.kitobId == kitobId);
    final r = Reja(kitobId: kitobId, boshKun: Reja.bugun(), kunlar: kunlar);
    rejalar.add(r);
    await _save();
    return r;
  }

  Future<void> ochir(String kitobId) async {
    rejalar.removeWhere((r) => r.kitobId == kitobId);
    await _save();
  }

  Future<void> belgila(Reja r, int kun, Vazifa v, bool bajarildi) async {
    final s = r.bajarilgan.putIfAbsent(kun, () => <String>{});
    if (bajarildi) {
      s.add(v.name);
      if (r.kunTugadimi(kun)) _faolKunlar.add(Reja.bugun());
    } else {
      s.remove(v.name);
    }
    await _save();
  }

  Future<void> ilgakYoz(String kalit, String matn) async {
    final t = matn.trim();
    if (t.isEmpty) {
      ilgaklar.remove(kalit);
    } else {
      ilgaklar[kalit] = t;
    }
    await _save();
  }

  /// Zanjir: bugun (yoki kecha) bilan tugaydigan ketma-ket faol kunlar.
  /// Bugun hali ishlanmagan bo'lsa, zanjir uzilgan hisoblanmaydi.
  int get zanjir {
    var d = Reja.bugun();
    if (!_faolKunlar.contains(d)) d--;
    var n = 0;
    while (_faolKunlar.contains(d)) {
      n++;
      d--;
    }
    return n;
  }

  bool get bugunFaol => _faolKunlar.contains(Reja.bugun());

  /// Bugun ishlanmagan (tugamagan) rejalar bormi.
  bool get bugunKutyapti => rejalar.any(
    (r) => !r.tugadi && r.joriyKun <= r.kalendarKun && !r.kunTugadimi(r.joriyKun),
  );

  Future<void> eslatmaQoy(int? daqiqa) async {
    eslatmaDaqiqa = daqiqa;
    await _save();
  }

  /// Eslatma vaqti kelganmi (bugun hali eslatilmagan va reja kutyapti).
  bool eslatishKerak(DateTime hozir) {
    final e = eslatmaDaqiqa;
    if (e == null || !bugunKutyapti) return false;
    if (_eslatildi == Reja.bugun()) return false;
    return hozir.hour * 60 + hozir.minute >= e;
  }

  Future<void> eslatildi() async {
    _eslatildi = Reja.bugun();
    await _save();
  }

  Timer? _kuzatuv;

  /// Har daqiqada tekshiradi: eslatma vaqti kelgan va bugungi reja
  /// bajarilmagan bo'lsa — brauzer bildirishnomasi (kuniga bir marta).
  void kuzatuvniBoshla() {
    _kuzatuv?.cancel();
    void tekshir() {
      if (!eslatishKerak(DateTime.now())) return;
      final r = rejalar.firstWhere((r) => !r.tugadi);
      eslatmaKorsat(
        'Bugungi yodlash rejasi kutyapti',
        "${r.kitob?.nom ?? ''}: ${r.joriyKun + 1}-kun. Zanjirni uzmang — "
            "minimal planka ham kunni saqlab qoladi.",
      );
      eslatildi();
    }

    tekshir();
    _kuzatuv = Timer.periodic(const Duration(minutes: 1), (_) => tekshir());
  }

  @visibleForTesting
  void tozala() {
    rejalar.clear();
    ilgaklar.clear();
    _faolKunlar.clear();
    eslatmaDaqiqa = null;
    _eslatildi = -1;
  }
}
