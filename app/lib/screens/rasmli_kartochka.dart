import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../arabic.dart';
import '../content.dart';
import '../main.dart';
import '../mnemonika/reja.dart';
import '../rasm.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/uz_text.dart';

/// «Rasmli kartochka» — dars lug'ati kartalarda so'raladi: tepada rasm,
/// tagida o'zbekcha ma'no, o'quvchi arabchasini topadi.
///
/// Rasm faqat konkret narsaga bor ([Rasm]); fe'l va mavhum so'zga noto'g'ri
/// rasm qo'yilmaydi — ularda rasm o'rnida mnemonik sahna (ilgak) turadi.
/// Xato topilgan karta navbat oxiriga qaytadi, fe'llar ikki marta chiqadi.
class RasmliKartochka extends StatefulWidget {
  final QiroatLesson lesson;
  const RasmliKartochka({super.key, required this.lesson});

  /// So'zning asosiy arabcha shakli.
  static String bosh(QiroatVocab v) => splitForms(v.ar.split('=').first).first;

  @override
  State<RasmliKartochka> createState() => _RasmliKartochkaState();
}

class _RasmliKartochkaState extends State<RasmliKartochka> {
  final _rnd = Random();
  late final List<QiroatVocab> _sozlar = [
    for (final v in widget.lesson.vocab)
      if (v.ar.trim().isNotEmpty && v.uz.trim().isNotEmpty) v,
  ];
  late final List<QiroatVocab> _navbat = [
    ..._sozlar,
    ..._sozlar.where((v) => v.felShakllari.isNotEmpty),
  ]..shuffle(_rnd);
  late final int _jami = _navbat.length;
  List<String> _variantlar = const [];
  String? _tanlangan;
  int _togri = 0;
  int _xato = 0;

  @override
  void initState() {
    super.initState();
    if (_navbat.isNotEmpty) _variantYasa();
  }

  @override
  void dispose() {
    Tts.instance.stop();
    super.dispose();
  }

  void _variantYasa() {
    final v = _navbat.first;
    final togri = RasmliKartochka.bosh(v);
    final boshqa =
        _sozlar
            .where((s) => s.uz != v.uz)
            .map(RasmliKartochka.bosh)
            .where((s) => s != togri)
            .toSet()
            .toList()
          ..shuffle(_rnd);
    _variantlar = [togri, ...boshqa.take(3)]..shuffle(_rnd);
  }

  void _tanla(String s) {
    if (_tanlangan != null) return;
    final v = _navbat.first;
    final togri = RasmliKartochka.bosh(v);
    final ok = s == togri;
    ok ? Haptic.ok() : Haptic.wrong();
    setState(() {
      _tanlangan = s;
      ok ? _togri++ : _xato++;
    });
    Tts.instance.speak(togri, id: 'rasmli-$togri');
    progress.bumpWord('${widget.lesson.completionId}::${v.ar}', ok);
    if (ok) progress.addXp(2);
  }

  void _keyingi() {
    final v = _navbat.removeAt(0);
    if (RasmliKartochka.bosh(v) != _tanlangan) _navbat.add(v);
    setState(() {
      _tanlangan = null;
      if (_navbat.isNotEmpty) _variantYasa();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Rasmli kartochka — ${widget.lesson.num}-dars'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _navbat.isEmpty ? _yakun() : _karta(),
        ),
      ),
    );
  }

  Widget _yakun() => Reveal(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.gold,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            'Hamma kartochka topildi!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_jami ta karta, $_xato marta xato qildingiz.',
            style: TextStyle(color: AppColors.matn2),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tugatish'),
          ),
        ],
      ),
    ),
  );

  Widget _karta() {
    final v = _navbat.first;
    final togri = RasmliKartochka.bosh(v);
    final rasm = Rasm.topish(v.uz);
    final ilgak = RejaXotira.instance.tayyorIlgak(togri);
    final javob = _tanlangan != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        AnimatedBar(
          value: _togri / _jami,
          height: 7,
          color: AppColors.gold,
          background: AppColors.gold.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 6),
        Text(
          '$_togri / $_jami  ·  arabchasini toping',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.matn2, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SlideSwitch(
          child: Container(
            key: ValueKey('karta-${_navbat.length}-${v.ar}'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.deep, AppColors.emeraldDark],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deep.withValues(alpha: 0.3),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                if (rasm != null)
                  Text(
                    rasm,
                    key: const ValueKey('karta-rasm'),
                    style: const TextStyle(fontSize: 92, height: 1.15),
                  )
                else if (ilgak != null)
                  Container(
                    key: const ValueKey('karta-sahna'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      ilgak.sahna,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  v.uz,
                  key: const ValueKey('karta-uz'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final (i, s) in _variantlar.indexed) ...[
          _variant(i, s, togri),
          const SizedBox(height: 9),
        ],
        if (javob && ilgak != null && rasm != null) ...[
          Text(
            ilgak.sahna,
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.matn2),
          ),
          const SizedBox(height: 10),
        ],
        if (javob)
          FilledButton(
            key: const ValueKey('karta-keyingi'),
            onPressed: _keyingi,
            child: Text('Keyingi'),
          ),
      ],
    );
  }

  Widget _variant(int i, String s, String togri) {
    final javob = _tanlangan != null;
    final rang = !javob
        ? AppColors.chiziq2
        : s == togri
        ? AppColors.success
        : s == _tanlangan
        ? AppColors.coral
        : AppColors.chiziq2;
    return Tactile(
      child: InkWell(
        key: ValueKey('karta-variant-$i'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => _tanla(s),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: javob && rang != AppColors.chiziq2
                ? rang.withValues(alpha: 0.1)
                : AppColors.karta,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: rang, width: 1.5),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(s, style: AppTheme.arabic(size: 28, height: 1.7)),
          ),
        ),
      ),
    );
  }
}
