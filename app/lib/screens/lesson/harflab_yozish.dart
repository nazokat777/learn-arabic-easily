import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../../arabic.dart';
import '../../content.dart';
import '../../harflab.dart';
import '../../main.dart';
import '../../mashq/mukofot.dart' show Portlash;
import '../../mashq/tovush.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import '../../widgets/entrance.dart';
import '../../widgets/motion.dart';
import '../../widgets/rasm_belgi.dart';
import '../../widgets/speak_button.dart';
import '../../widgets/uz_text.dart';

/// «Harflab yozish» — so'zning ma'nosi va ovozi beriladi, o'quvchi harflarni
/// TO'G'RI TARTIBDA bosib so'zni yig'adi. Har bosilgan harfning NOMI
/// aytiladi (inson ovozi), so'z tugagach butun so'z o'qiladi.
///
/// Nega: «doska» ni ko'rib tanish bilan uni harflab yoza olish — ikki xil
/// bilim. Harfma-harf yig'ish imloni qo'l xotirasiga o'tkazadi; noto'g'ri
/// harf jazosiz — faqat silkinadi, o'quvchi yana urinadi.
class HarflabYozishEkrani extends StatefulWidget {
  /// (arabcha so'z, ma'nosi) — Qiroat darsi lug'atidan yoki Ulash bosqichi
  /// so'zlaridan.
  final List<({String ar, String uz})> sozRoyxati;

  /// So'z → xotira kaliti (progress.bumpWord). Berilsa, har so'zning
  /// natijasi «yodlangan» hisobiga yoziladi (imtihon shunga tayanadi).
  final Map<String, String> kalitlar;
  final String sarlavha;
  HarflabYozishEkrani({super.key, required QiroatLesson lesson})
    : sozRoyxati = sozlar(lesson),
      kalitlar = const {},
      sarlavha = 'Harflab yozish';
  const HarflabYozishEkrani.royxat({
    super.key,
    required this.sozRoyxati,
    this.kalitlar = const {},
    this.sarlavha = 'Harflab yozish',
  });

  /// Ulash bosqichi so'zlari — 2–8 harflilari.
  static List<({String ar, String uz})> ulashSozlari(
    Iterable<({String ar, String uz})> words,
  ) => [
    for (final w in words)
      if (harflab(w.ar).length >= 2 && harflab(w.ar).length <= 8)
        (ar: w.ar, uz: w.uz),
  ];

  /// Darsdan mashq uchun so'zlar: bosh shakl, 2–8 harfli (juda uzun so'z
  /// bir ekranga sig'maydi, bir harfli so'zda mashq yo'q).
  static List<({String ar, String uz})> sozlar(QiroatLesson l) {
    final out = <({String ar, String uz})>[];
    final korilgan = <String>{};
    for (final v in l.vocab) {
      final forms = splitForms(v.ar);
      final head = (forms.isNotEmpty ? forms.first : v.ar).trim();
      if (head.contains(' ')) continue; // ibora — so'z emas
      final n = harflab(head).length;
      if (n < 2 || n > 8) continue;
      if (!korilgan.add(stripDiacritics(head))) continue;
      out.add((ar: head, uz: v.uz));
    }
    return out;
  }

  @override
  State<HarflabYozishEkrani> createState() => _HarflabYozishEkraniState();
}

class _HarflabYozishEkraniState extends State<HarflabYozishEkrani> {
  final _rnd = Random();
  late final List<({String ar, String uz})> _sozlar =
      List.of(widget.sozRoyxati)..shuffle(_rnd);
  int _i = 0;
  late List<HarfBolagi> _asl;
  late List<HarfBolagi> _havza; // aralashgan harflar + chalg'ituvchilar
  final List<int> _tanlangan = []; // havza indekslari
  int _xato = 0; // shu so'zda nechta xato bosildi
  int _silkin = 0;
  int _portlash = 0;
  int _togri = 0; // birinchi urinishda xatosiz yig'ilganlar
  bool _tugadi = false;
  bool _tugallandi = false; // shu so'z yig'ildi

  @override
  void initState() {
    super.initState();
    if (_sozlar.isNotEmpty) _yukla();
  }

  @override
  void dispose() {
    Tts.instance.stop();
    super.dispose();
  }

  void _yukla() {
    _asl = harflab(_sozlar[_i].ar);
    // Chalg'ituvchi: so'zda yo'q 2 ta harf — o'quvchi «qolgan harfni bos»
    // hiylasi bilan o'tib ketmasin.
    final bor = _asl.map((h) => h.harf).toSet();
    final boshqa = repo.letters
        .map((l) => l.ar)
        .where((c) => !bor.contains(c))
        .toList()
      ..shuffle(_rnd);
    _havza = [
      ..._asl,
      for (final c in boshqa.take(2)) HarfBolagi(c, harfNomi(c) ?? c),
    ]..shuffle(_rnd);
    _tanlangan.clear();
    _xato = 0;
    _tugallandi = false;
    // So'z avval eshittiriladi — o'quvchi eshitgan so'zini yozadi.
    final i = _i;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _i == i) Tts.instance.speak(_sozlar[i].ar, id: 'hy-$i');
    });
  }

  void _bos(int idx) {
    if (_tugallandi) return;
    final k = _tanlangan.length;
    final kerak = _asl[k];
    final bosilgan = _havza[idx];
    if (bosilgan.harf == kerak.harf && !_tanlangan.contains(idx)) {
      Haptic.tap();
      setState(() => _tanlangan.add(idx));
      Tts.instance.speak(bosilgan.nom, id: 'hy-h$k');
      if (_tanlangan.length == _asl.length) _yakunla();
    } else {
      Haptic.wrong();
      Tovush.xato();
      setState(() {
        _xato++;
        _silkin++;
      });
    }
  }

  Future<void> _yakunla() async {
    setState(() {
      _tugallandi = true;
      _portlash++;
      if (_xato == 0) _togri++;
    });
    Haptic.ok();
    Tovush.togri(_xato == 0 ? _togri : 0);
    progress.addXp(_xato == 0 ? 3 : 1);
    final kalit = widget.kalitlar[_sozlar[_i].ar];
    if (kalit != null) progress.bumpWord(kalit, _xato == 0);
    // Oxirgi harf nomi tugasin, keyin butun so'z o'qilsin.
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted && _tugallandi) {
      await Tts.instance.speak(_sozlar[_i].ar, id: 'hy-soz-$_i');
    }
  }

  void _keyingi() {
    if (_i + 1 >= _sozlar.length) {
      setState(() => _tugadi = true);
      return;
    }
    setState(() {
      _i++;
      _yukla();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sarlavha)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _sozlar.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text("Bu darsda harflab yoziladigan so'z yo'q."),
                )
              : _tugadi
              ? _yakun()
              : _mashq(),
        ),
      ),
    );
  }

  Widget _mashq() {
    final s = _sozlar[_i];
    final yigilgan = _tanlangan.map((i) => _havza[i].harf).join();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            const Icon(
              Icons.spellcheck_rounded,
              size: 18,
              color: AppColors.indigo,
            ),
            const SizedBox(width: 6),
            Text(
              "So'zni harflab yozing",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Text(
              '${_i + 1} / ${_sozlar.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBar(
          value: (_i + (_tugallandi ? 1 : 0)) / _sozlar.length,
          height: 6,
          color: AppColors.indigo,
          background: AppColors.indigo.withValues(alpha: 0.12),
        ),
        const SizedBox(height: 18),
        // Savol: ma'no + rasm + ovoz (so'zning o'zi ko'rsatilmaydi).
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.karta,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              RasmBelgi(uz: s.uz, olcham: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.uz,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              SpeakButton(text: s.ar, id: 'hy-$_i', size: 26),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Yig'ilayotgan so'z — o'ngdan chapga, tugagach harakatli asl shakl.
        Portlash(
          trigger: _portlash == 0 ? null : _portlash,
          ranglar: const [AppColors.success, AppColors.gold, AppColors.emerald],
          child: Shake(
            trigger: _silkin == 0 ? null : _silkin,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 84),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _tugallandi
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.karta,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _tugallandi ? AppColors.success : AppColors.chiziq2,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  _tugallandi ? s.ar : (yigilgan.isEmpty ? '…' : yigilgan),
                  style: AppTheme.arabic(
                    size: 40,
                    color: _tugallandi ? AppColors.success : AppColors.emerald,
                    w: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _tugallandi
              ? (_xato == 0 ? "Xatosiz! To'g'ri yozdingiz." : "To'g'ri yozdingiz.")
              : "Harflarni tartib bilan bosing — har harf nomi aytiladi.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.matn2, fontSize: 13),
        ),
        const SizedBox(height: 18),
        // Harflar havzasi
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          textDirection: TextDirection.rtl,
          children: [
            for (var k = 0; k < _havza.length; k++)
              _harfChip(k, ishlatilgan: _tanlangan.contains(k)),
          ],
        ),
        const SizedBox(height: 24),
        if (_tugallandi)
          PressableScale(
            child: FilledButton.icon(
              onPressed: _keyingi,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _i + 1 >= _sozlar.length ? 'Yakunlash' : "Keyingi so'z",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _harfChip(int k, {required bool ishlatilgan}) {
    final h = _havza[k];
    return PressableScale(
      child: Material(
        color: ishlatilgan
            ? AppColors.chiziq2.withValues(alpha: 0.5)
            : AppColors.softGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: ishlatilgan ? null : () => _bos(k),
          child: Container(
            width: 58,
            height: 62,
            alignment: Alignment.center,
            child: Text(
              h.harf,
              style: AppTheme.arabic(
                size: 32,
                color: ishlatilgan ? AppColors.matn3 : AppColors.zumradMatn,
                w: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _yakun() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Reveal(
          fromScale: 0.6,
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 96,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_sozlar.length} so\'z harflab yozildi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Xatosiz: $_togri / ${_sozlar.length}',
          style: TextStyle(fontSize: 16, color: AppColors.matn2),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
          child: const Text('Darsga qaytish'),
        ),
      ],
    ),
  );
}
