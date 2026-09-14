import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../arabic.dart';
import '../content.dart';
import '../main.dart';
import '../mashq/mukofot.dart';
import '../mashq/tovush.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/speak_button.dart';
import '../widgets/uz_text.dart';

/// «Bo'sh joy» — kitob matnidagi jumla, ichidan bitta lug'at so'zi olib
/// tashlangan; o'quvchi uni variantlardan qaytaradi.
///
/// Nega kuchli: so'z alohida emas, KONTEKSTDA eslanadi (transfer-appropriate
/// processing) — matnni o'qiganda so'z «o'z joyidan» tanish bo'ladi.
/// Variantlar ham shu dars matnidan olingan haqiqiy so'zlar (harakati bilan),
/// shuning uchun ko'rinishidan javob bilinib qolmaydi. Mazmun — kitobniki.
class BoshJoy {
  final String jumla; // to'liq jumla (ovoz uchun)
  final String oldi; // bo'sh joydan oldingi qism
  final String soz; // olib tashlangan so'z (matndagi shakli)
  final String keyin; // bo'sh joydan keyingi qism
  final QiroatVocab lugat; // qaysi lug'at so'zi
  const BoshJoy({
    required this.jumla,
    required this.oldi,
    required this.soz,
    required this.keyin,
    required this.lugat,
  });

  /// Darsdan bo'sh joy topshiriqlari: har lug'at so'zi uchun matnda aynan
  /// (yoki «ال/وَ/بِ/لِ/فَ» old qo'shimchasi bilan) uchragan birinchi jumla.
  static List<BoshJoy> yasa(QiroatLesson l) {
    final natija = <BoshJoy>[];
    final ishlatilgan = <String>{}; // bir jumla — bir marta
    final jumlalar = splitSentences(l.reading);
    for (final v in l.vocab) {
      final shakllar = splitForms(
        v.ar,
      ).map(stripDiacritics).where((s) => s.length >= 2).toList();
      if (shakllar.isEmpty) continue;
      BoshJoy? topildi;
      for (final j in jumlalar) {
        if (ishlatilgan.contains(j)) continue;
        final t = tokenize(j);
        for (var i = 0; i < t.length; i++) {
          if (!t[i].isWord) continue;
          if (!_mos(stripDiacritics(t[i].text), shakllar)) continue;
          topildi = BoshJoy(
            jumla: j,
            oldi: t.sublist(0, i).map((x) => x.text).join(),
            soz: t[i].text,
            keyin: t.sublist(i + 1).map((x) => x.text).join(),
            lugat: v,
          );
          break;
        }
        if (topildi != null) break;
      }
      if (topildi != null) {
        ishlatilgan.add(topildi.jumla);
        natija.add(topildi);
      }
    }
    return natija;
  }

  static bool _mos(String token, List<String> shakllar) {
    for (final s in shakllar) {
      if (token == s) return true;
      for (final p in const [
        'ال',
        'وال',
        'بال',
        'لل',
        'فال',
        'و',
        'ب',
        'ل',
        'ف',
      ]) {
        if (token.startsWith(p) && token.substring(p.length) == s) return true;
      }
    }
    return false;
  }
}

class BoshJoyEkrani extends StatefulWidget {
  final QiroatLesson lesson;
  const BoshJoyEkrani({super.key, required this.lesson});

  @override
  State<BoshJoyEkrani> createState() => _BoshJoyEkraniState();
}

class _BoshJoyEkraniState extends State<BoshJoyEkrani> {
  final _rnd = Random();
  late final List<BoshJoy> _hammasi;
  late List<BoshJoy> _navbat;
  int _i = 0;
  List<String> _variantlar = const [];
  int? _tanlangan;
  bool _javobBerildi = false;
  int _togri = 0;
  int _ketmaKet = 0;
  int _portlash = 0;
  String _fikr = '';

  BoshJoy get _joriy => _navbat[_i];
  bool get _tugadi => _i >= _navbat.length;

  @override
  void initState() {
    super.initState();
    _hammasi = BoshJoy.yasa(widget.lesson);
    _navbat = List.of(_hammasi)..shuffle(_rnd);
    if (_navbat.isNotEmpty) _savolYasa();
  }

  void _savolYasa() {
    final j = _joriy;
    final boshqa =
        _hammasi
            .where((b) => stripDiacritics(b.soz) != stripDiacritics(j.soz))
            .map((b) => b.soz)
            .toSet()
            .toList()
          ..shuffle(_rnd);
    _variantlar = <String>[j.soz, ...boshqa.take(3)]..shuffle(_rnd);
    _tanlangan = null;
    _javobBerildi = false;
    _fikr = '';
  }

  Future<void> _tanla(int i) async {
    if (_javobBerildi) return;
    final ok = _variantlar[i] == _joriy.soz;
    ok ? Haptic.ok() : Haptic.wrong();
    ok ? Tovush.togri(_ketmaKet + 1) : Tovush.xato();
    setState(() {
      _tanlangan = i;
      _javobBerildi = true;
      if (ok) {
        _togri++;
        _ketmaKet++;
        _portlash++;
        _fikr = Maqtov.togri(_rnd, ketmaKet: _ketmaKet);
      } else {
        _ketmaKet = 0;
        _fikr = Maqtov.xato(_rnd);
      }
    });
    if (ok) progress.addXp(2);
    // To'liq jumla o'qiladi — so'z o'z o'rnida eshitiladi.
    Tts.instance.speak(_joriy.jumla, id: 'bosh-joy');
    await progress.bumpWord(
      '${widget.lesson.completionId}::${_joriy.lugat.ar}',
      ok,
    );
  }

  void _keyingi() {
    Haptic.tap();
    setState(() {
      _i++;
      if (!_tugadi) _savolYasa();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bo'sh joy"),
        actions: [
          if (_navbat.isNotEmpty && !_tugadi)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${_i + 1} / ${_navbat.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _navbat.isEmpty ? _bosh() : (_tugadi ? _yakun() : _savol()),
    );
  }

  Widget _bosh() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(
        "Bu darsda lug'at so'zlari matnda aynan shaklda uchramaydi — "
        "bo'sh joy topshirig'i yo'q.",
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.matn2, height: 1.4),
      ),
    ),
  );

  Widget _savol() {
    final j = _joriy;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            Text(
              "Jumladagi bo'sh joyga qaysi so'z tushadi?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.matn3),
            ),
            const SizedBox(height: 14),
            Portlash(
              trigger: _portlash,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                decoration: BoxDecoration(
                  color: AppColors.karta,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTheme.arabic(size: 28, color: AppColors.ink),
                      children: [
                        TextSpan(text: j.oldi),
                        TextSpan(
                          text: _javobBerildi ? j.soz : ' ـــــــ ',
                          style: AppTheme.arabic(
                            size: 28,
                            color: _javobBerildi
                                ? AppColors.success
                                : AppColors.gold,
                            w: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: j.keyin),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "«${j.lugat.uz}» ma'nosidagi so'z",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.matn2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final (i, v) in _variantlar.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Variant(
                  matn: v,
                  holat: !_javobBerildi
                      ? _Holat.oddiy
                      : v == j.soz
                      ? _Holat.togri
                      : (i == _tanlangan ? _Holat.xato : _Holat.xira),
                  onTap: () => _tanla(i),
                ),
              ),
            if (_javobBerildi) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpeakButton(text: j.jumla, id: 'bosh-joy', size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _fikr,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color:
                          _tanlangan != null &&
                              _variantlar[_tanlangan!] == j.soz
                          ? AppColors.success
                          : AppColors.coral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _keyingi,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _i + 1 < _navbat.length ? 'Keyingi' : 'Yakunlash',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _yakun() {
    final n = _navbat.length;
    final foiz = (_togri * 100 / n).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              foiz >= 80
                  ? Icons.emoji_events_rounded
                  : Icons.check_circle_rounded,
              size: 64,
              color: foiz >= 80 ? AppColors.gold : AppColors.emerald,
            ),
            const SizedBox(height: 12),
            Text(
              '$_togri / $n to\'g\'ri',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              foiz >= 80
                  ? "So'zlar o'z o'rnida tanish — matn endi «sizniki»."
                  : "Matnni yana bir o'qib, qaytadan urinib ko'ring.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.matn2, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {
                    _navbat = List.of(_hammasi)..shuffle(_rnd);
                    _i = 0;
                    _togri = 0;
                    _ketmaKet = 0;
                    _savolYasa();
                  }),
                  child: const Text(
                    'Yana',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                  ),
                  child: const Text(
                    'Tayyor',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _Holat { oddiy, togri, xato, xira }

class _Variant extends StatelessWidget {
  final String matn;
  final _Holat holat;
  final VoidCallback onTap;
  const _Variant({
    required this.matn,
    required this.holat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rang = switch (holat) {
      _Holat.togri => AppColors.success,
      _Holat.xato => AppColors.coral,
      _ => AppColors.chiziq2,
    };
    return Shake(
      trigger: holat == _Holat.xato ? matn : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: holat == _Holat.xira ? 0.45 : 1,
        child: Material(
          color: holat == _Holat.togri
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.karta,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: rang,
                  width: holat == _Holat.oddiy ? 1 : 2,
                ),
              ),
              child: Text(
                matn,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTheme.arabic(size: 24, color: AppColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
