import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../../main.dart';
import '../../mashq/mukofot.dart' show Maqtov, Portlash;
import '../../mashq/soz_lugat.dart';
import '../../mashq/tovush.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import '../../widgets/entrance.dart';
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
  ///
  /// O'zbekchasi BO'SH bo'lsa — «tinglab tuzish»: gap avval ovozda
  /// eshittiriladi (o'zi ijro etiladi, qayta tinglash tugmasi bor), o'quvchi
  /// eshitganini so'zlardan yig'adi. Bu quloq mashqi — yozuvsiz tushunish.
  final List<(String, String)> juftlar;
  final void Function(int ball) award;
  final VoidCallback onDone;
  final Random? rnd;

  /// Tinglab tuzish rejimi: har gap avval ovozda eshittiriladi (o'zi ijro
  /// etiladi, qayta tinglash tugmasi bor); o'zbekchasi bo'lsa — yordamchi
  /// sifatida pastroqda ko'rsatiladi.
  final bool tinglab;

  const GapTuzish({
    super.key,
    required this.juftlar,
    required this.award,
    required this.onDone,
    this.rnd,
    this.tinglab = false,
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
  bool _tarjimaKorsat = true; // chip ostida so'z ma'nosi

  @override
  void initState() {
    super.initState();
    _yukla();
  }

  @override
  void dispose() {
    Tts.instance.stop();
    super.dispose();
  }

  bool get _tinglab =>
      widget.tinglab || widget.juftlar[_i].$1.trim().isEmpty;

  /// Tinglab tuzishda gap ochilishi bilan o'qiladi (kichik kechikish —
  /// chip'lar chizilib bo'lsin).
  void _avtoOqi() {
    if (!_tinglab) return;
    final i = _i;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _i == i && _natija == null) {
        Tts.instance.speak(widget.juftlar[i].$2, id: 'gap-eshit-$i');
      }
    });
  }

  void _yukla() {
    _avtoOqi();
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
      progress.hisobQosh(gap: 1);
    } else {
      Haptic.wrong();
      Tovush.xato();
    }
    Tts.instance.speak(widget.juftlar[_i].$2, id: 'gap-$_i');
  }

  /// «Qanday tuziladi?» — to'g'ri tartib, har so'zning ma'nosi, qadamlar.
  void _qanday(String uz, String ar) {
    final sozlar = GapTuzish.sozlar(ar);
    Tts.instance.speak(ar, id: 'gap-qanday-$_i');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.karta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              Text(
                "Gapni qanday tuzamiz?",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              if (uz.trim().isNotEmpty)
                Text(
                  uz,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.indigo,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                "Arabcha o'ngdan chapga o'qiladi. So'zlarni mana shu tartibda, "
                "birinchisidan boshlab bosing:",
                style: TextStyle(fontSize: 13, color: AppColors.matn3, height: 1.35),
              ),
              const SizedBox(height: 10),
              for (final (k, w) in sozlar.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.indigo.withValues(alpha: 0.14),
                        child: Text(
                          '${k + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: AppColors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          SozLugat.tarjima(w) ?? "(alohida ma'nosi lug'atda yo'q)",
                          style: TextStyle(fontSize: 14, color: AppColors.ink),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        w,
                        textDirection: TextDirection.rtl,
                        style: AppTheme.arabic(size: 24, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Text(
                ar,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTheme.arabic(size: 24, color: AppColors.success),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tushundim'),
              ),
            ],
          ),
        ),
      ),
    );
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
        if (_tinglab) _EshitishTugmasi(text: ar, id: 'gap-eshit-$_i'),
        if (_tinglab && uz.trim().isNotEmpty) const SizedBox(height: 10),
        if (!_tinglab || uz.trim().isNotEmpty)
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
                        tarjima: _tarjimaKorsat ? SozLugat.tarjima(_asl[idx]) : null,
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
                      tarjima: _tarjimaKorsat ? SozLugat.tarjima(_asl[idx]) : null,
                      rang: AppColors.indigo,
                      tolgan: false,
                      onTap: () => _tanla(idx),
                    ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _tarjimaKorsat = !_tarjimaKorsat),
              icon: Icon(
                _tarjimaKorsat
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 18,
              ),
              label: Text(
                _tarjimaKorsat ? "So'z ma'nolari: yoqiq" : "So'z ma'nolari: o'chiq",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
            TextButton.icon(
              onPressed: () => _qanday(uz, ar),
              icon: const Icon(Icons.lightbulb_rounded, size: 18),
              label: const Text(
                'Qanday tuziladi?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
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
  final String? tarjima;
  final VoidCallback onTap;
  const _Chip({
    this.tarjima,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  matn,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabic(size: 21, color: AppColors.ink),
                ),
                if (tarjima != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      tarjima!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.15,
                        color: AppColors.matn3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Tinglab tuzish rejimining «savoli»: gap yozuvsiz, faqat ovoz.
class _EshitishTugmasi extends StatelessWidget {
  final String text;
  final String id;
  const _EshitishTugmasi({required this.text, required this.id});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: Tts.instance.speakingId,
      builder: (context, speaking, _) {
        final active = speaking == id;
        return Center(
          child: PressableScale(
            child: Material(
              color: active ? AppColors.gold : AppColors.indigo,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Tts.instance.speak(text, id: id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? Icons.graphic_eq_rounded : Icons.hearing_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Tinglang va gapni tuzing',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
