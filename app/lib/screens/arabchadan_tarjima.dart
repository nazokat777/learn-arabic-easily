import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../arabic.dart';
import '../content.dart';
import '../main.dart';
import '../mashq/tovush.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/speak_button.dart';
import '../widgets/uz_text.dart';
import 'lesson/sentence_text.dart';

/// Bitta topshiriq: kitob matnidagi arabcha gap(lar) va kitobdagi tarjimasi.
typedef TarjimaTopshiriq = ({List<String> ar, String uz});

/// «Mashq: arabchadan o'zbekchaga» — darsning kitobdagi arabcha matni gapma-gap
/// so'raladi: o'quvchi avval o'zi tarjima qiladi, keyin kitob tarjimasini
/// variantlardan topadi. Xato topilgan gap navbat oxiriga qaytadi.
///
/// Erkin yozilgan o'zbekcha tarjimani to'g'ri baholab bo'lmaydi (bir gapning
/// ko'p to'g'ri tarjimasi bor), shuning uchun tanlash. Variantlar shu darsning
/// o'z tarjimalari — mazmun kitobdagining o'zi.
class ArabchadanTarjima extends StatefulWidget {
  final QiroatLesson lesson;
  final void Function(int ball) award;
  final VoidCallback onDone;
  const ArabchadanTarjima({
    super.key,
    required this.lesson,
    required this.award,
    required this.onDone,
  });

  /// Tarjimasi bor hamma gap guruhlari, kitob tartibida.
  static List<TarjimaTopshiriq> topshiriqlar(QiroatLesson l) {
    final gaplar = splitSentences(l.reading);
    return [
      for (final g in l.tarjimaGuruhlari)
        if (g.matn.trim().isNotEmpty && g.boshi + g.soni <= gaplar.length)
          (ar: gaplar.sublist(g.boshi, g.boshi + g.soni), uz: g.matn.trim()),
    ];
  }

  @override
  State<ArabchadanTarjima> createState() => _ArabchadanTarjimaState();
}

class _ArabchadanTarjimaState extends State<ArabchadanTarjima> {
  final _rnd = Random();
  late final List<TarjimaTopshiriq> _hammasi = ArabchadanTarjima.topshiriqlar(
    widget.lesson,
  );
  late final List<TarjimaTopshiriq> _navbat = [..._hammasi];
  late final int _jami = _hammasi.length;
  List<String> _variantlar = const [];
  String? _tanlangan;
  int _togri = 0;

  @override
  void initState() {
    super.initState();
    if (_navbat.isNotEmpty) {
      _variantYasa();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDone();
      });
    }
  }

  void _variantYasa() {
    final togri = _navbat.first.uz;
    final boshqa =
        _hammasi.map((t) => t.uz).where((u) => u != togri).toSet().toList()
          ..shuffle(_rnd);
    _variantlar = [togri, ...boshqa.take(3)]..shuffle(_rnd);
  }

  void _tanla(String s) {
    if (_tanlangan != null) return;
    final ok = s == _navbat.first.uz;
    setState(() {
      _tanlangan = s;
      if (ok) _togri++;
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
  }

  void _keyingi() {
    final t = _navbat.removeAt(0);
    if (_tanlangan != t.uz) _navbat.add(t);
    if (_navbat.isEmpty) {
      widget.onDone();
      return;
    }
    setState(() {
      _tanlangan = null;
      _variantYasa();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_navbat.isEmpty) return const SizedBox.shrink();
    final t = _navbat.first;
    final l = widget.lesson;
    final javob = _tanlangan != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        Text(
          "Arabchadan o'zbekchaga",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "Kitobdagi matn. Gapni avval o'zingiz tarjima qiling, keyin "
          "to'g'ri tarjimani tanlang.",
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.matn2,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedBar(
          value: _jami == 0 ? 1 : _togri / _jami,
          height: 7,
          color: AppColors.gold,
          background: AppColors.gold.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 4),
        Text(
          '$_togri / $_jami',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.matn2, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Container(
          key: const ValueKey('at-savol'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.karta,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (k, gap) in t.ar.indexed)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SpeakButton(
                      text: gap,
                      id: 'at-${t.uz.hashCode}-$k',
                      size: 18,
                    ),
                    Expanded(
                      child: SentenceText(
                        sentence: gap,
                        vocab: l.vocab,
                        reading: l.reading,
                        lessonId: l.completionId,
                        size: 23,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final (i, s) in _variantlar.indexed) ...[
          _variant(i, s, t.uz),
          const SizedBox(height: 9),
        ],
        if (javob)
          FilledButton(
            key: const ValueKey('at-keyingi'),
            onPressed: _keyingi,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
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
        key: ValueKey('at-variant-$i'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => _tanla(s),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: javob && rang != AppColors.chiziq2
                ? rang.withValues(alpha: 0.1)
                : AppColors.karta,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: rang, width: 1.5),
          ),
          child: Text(
            s,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mashqning alohida ekrani («To'liq dars» sahifasidan ochiladi).
class ArabchadanTarjimaEkrani extends StatelessWidget {
  final QiroatLesson lesson;
  const ArabchadanTarjimaEkrani({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text('${lesson.num}-dars — tarjima mashqi')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ArabchadanTarjima(
            lesson: lesson,
            award: progress.addXp,
            onDone: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}
