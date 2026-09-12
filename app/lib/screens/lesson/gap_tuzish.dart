import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../../mashq/mukofot.dart' show Maqtov, Portlash;
import '../../mashq/tovush.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/uz_text.dart';

/// Gap tuzish — o'zbekcha gap beriladi, arabcha so'zlar aralash chip'lar;
/// o'quvchi ularni to'g'ri tartibda bosib gapni tuzadi.
///
/// Nega: «javobni ochish» passiv; so'zlarni o'zi tartiblash — faol
/// eslash + sintaksis hissi (fe'l–ega–to'ldiruvchi tartibi qo'l bilan
/// o'rganiladi). Har to'g'ri gap — kichik g'alaba (tovush, ball); xato —
/// jazosiz: to'g'ri javob ko'rsatiladi, keyingisiga o'tiladi.
/// Juftlar kitob mashqidan (o'zbekcha ↔ arabcha javob) — mazmun o'sha.
class GapTuzish extends StatefulWidget {
  /// (o'zbekcha gap, arabcha javob) juftlari.
  final List<(String, String)> juftlar;
  final void Function(int ball) award;
  final VoidCallback onDone;
  final Random? rnd;

  const GapTuzish({
    super.key,
    required this.juftlar,
    required this.award,
    required this.onDone,
    this.rnd,
  });

  /// So'zlarga bo'lish (bo'sh joy bo'yicha; tinish belgilari so'zga yopishiq).
  static List<String> sozlar(String ar) =>
      ar.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

  @override
  State<GapTuzish> createState() => _GapTuzishState();
}

class _GapTuzishState extends State<GapTuzish> {
  late final Random _rnd = widget.rnd ?? Random();
  int _i = 0;
  List<String> _asl = const [];
  List<int> _havza = const []; // aralashgan indekslar (asl bo'yicha)
  final List<int> _tanlangan = [];
  bool? _natija; // null — tekshirilmagan
  int _togri = 0;
  int _portlash = 0;
  int _silkin = 0;

  @override
  void initState() {
    super.initState();
    _yukla();
  }

  void _yukla() {
    _asl = GapTuzish.sozlar(widget.juftlar[_i].$2);
    var h = List.generate(_asl.length, (k) => k)..shuffle(_rnd);
    // Bir so'zli gap bo'lmasa, aralashgani asl bilan bir xil chiqmasin.
    var urinish = 0;
    while (_asl.length > 1 && _aslTartibmi(h) && urinish < 10) {
      h = List.generate(_asl.length, (k) => k)..shuffle(_rnd);
      urinish++;
    }
    _havza = h;
    _tanlangan.clear();
    _natija = null;
  }

  bool _aslTartibmi(List<int> h) {
    for (var k = 0; k < h.length; k++) {
      if (h[k] != k) return false;
    }
    return true;
  }

  void _tanla(int idx) {
    if (_natija != null) return;
    Haptic.tap();
    setState(() => _tanlangan.add(idx));
  }

  void _qaytar(int pos) {
    if (_natija != null) return;
    setState(() => _tanlangan.removeAt(pos));
  }

  void _tekshir() {
    if (_tanlangan.length != _asl.length) return;
    // Bir xil so'zlar (masalan, «هَذَا» ikki marta) o'rin almashsa ham to'g'ri.
    var ok = true;
    for (var k = 0; k < _asl.length; k++) {
      if (_asl[_tanlangan[k]] != _asl[k]) {
        ok = false;
        break;
      }
    }
    setState(() {
      _natija = ok;
      if (ok) {
        _togri++;
        _portlash++;
      } else {
        _silkin++;
      }
    });
    if (ok) {
      Haptic.ok();
      Tovush.togri(_togri);
      widget.award(2);
    } else {
      Haptic.wrong();
      Tovush.xato();
    }
    Tts.instance.speak(widget.juftlar[_i].$2, id: 'gap-$_i');
  }

  void _keyingi() {
    if (_i + 1 >= widget.juftlar.length) {
      widget.onDone();
      return;
    }
    setState(() {
      _i++;
      _yukla();
    });
  }

  @override
  Widget build(BuildContext context) {
    final (uz, ar) = widget.juftlar[_i];
    final tayyor = _tanlangan.length == _asl.length;
    final rang = switch (_natija) {
      true => AppColors.success,
      false => AppColors.coral,
      null => AppColors.indigo,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.extension_rounded,
              size: 18,
              color: AppColors.indigo,
            ),
            const SizedBox(width: 6),
            Text(
              'Gap tuzish',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Text(
              '${_i + 1} / ${widget.juftlar.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBar(
          value: (_i + (_natija == null ? 0 : 1)) / widget.juftlar.length,
          height: 6,
          color: AppColors.indigo,
          background: AppColors.indigo.withValues(alpha: 0.12),
        ),
        const SizedBox(height: 14),
        Text(
          uz,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        // Javob maydoni — tanlangan so'zlar (o'ngdan chapga).
        Portlash(
          trigger: _portlash == 0 ? null : _portlash,
          ranglar: const [AppColors.success, AppColors.gold, AppColors.emerald],
          child: Shake(
            trigger: _silkin == 0 ? null : _silkin,
            child: Container(
              // Portlash/Shake cheklovlarni bo'shashtiradi — maydon
              // chip o'lchamiga qisqarib qolmasin, to'liq kenglik.
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: rang.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: rang.withValues(alpha: 0.5),
                  width: 1.4,
                ),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_tanlangan.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          "So'zlarni tartib bilan bosing",
                          style: TextStyle(
                            color: AppColors.matn3,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    for (final (pos, idx) in _tanlangan.indexed)
                      _Chip(
                        matn: _asl[idx],
                        rang: rang,
                        tolgan: true,
                        onTap: () => _qaytar(pos),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Havza — hali tanlanmagan so'zlar. Balandligi qat'iy: oxirgi so'z
        // tanlanganda havza bo'shab, tugmalar yuqoriga sakrab ketmasin —
        // aks holda «Tekshirish» o'rniga «Bilmadim» bosilib qoladi.
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          alignment: Alignment.center,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final idx in _havza)
                  if (!_tanlangan.contains(idx))
                    _Chip(
                      matn: _asl[idx],
                      rang: AppColors.indigo,
                      tolgan: false,
                      onTap: () => _tanla(idx),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_natija != null) ...[
          Text(
            _natija!
                ? Maqtov.togri(_rnd, ketmaKet: _togri)
                : "To'g'ri javob: $ar",
            textAlign: TextAlign.center,
            textDirection: _natija! ? TextDirection.ltr : TextDirection.rtl,
            style: _natija!
                ? TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                    fontSize: 15,
                  )
                : AppTheme.arabic(size: 20, color: AppColors.coral),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: _natija == null ? (tayyor ? _tekshir : null) : _keyingi,
          style: FilledButton.styleFrom(
            backgroundColor: _natija == null ? AppColors.indigo : rang,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            _natija == null
                ? 'Tekshirish'
                : (_i + 1 >= widget.juftlar.length
                      ? 'Tugatish'
                      : 'Keyingi gap'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        if (_natija == null)
          TextButton(
            onPressed: () {
              setState(() => _natija = false);
              Tts.instance.speak(ar, id: 'gap-$_i');
            },
            child: Text(
              "Bilmadim — javobni ko'rsat",
              style: TextStyle(
                color: AppColors.matn3,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String matn;
  final Color rang;
  final bool tolgan;
  final VoidCallback onTap;
  const _Chip({
    required this.matn,
    required this.rang,
    required this.tolgan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tactile(
      child: Material(
        color: tolgan ? rang.withValues(alpha: 0.14) : AppColors.karta,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: rang.withValues(alpha: tolgan ? 0.6 : 0.35),
              ),
            ),
            child: Text(
              matn,
              textDirection: TextDirection.rtl,
              style: AppTheme.arabic(size: 21, color: AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}
