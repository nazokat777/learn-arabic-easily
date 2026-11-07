import 'package:flutter/material.dart' hide Text;

import '../../arabic.dart';
import '../../content.dart';
import '../../main.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import '../../widgets/speak_button.dart';
import '../../widgets/uz_text.dart';

/// «Birligi va ko'pligini ayting» — faol eslash.
///
/// Ma'nosi beriladi, o'quvchi birlik va ko'plikni ovoz chiqarib aytadi, keyin
/// ochib o'zini tekshiradi. Ko'plikni ko'rib tanish yodlatmaydi — o'zi aytgani
/// yodda qoladi. Adashilgan so'z navbat oxirida bir marta qaytadi.
class BirlikKoplikAyt extends StatefulWidget {
  final List<QiroatVocab> sozlar;
  final String darsId;
  final VoidCallback onDone;
  final void Function(int xp)? award;
  const BirlikKoplikAyt({
    super.key,
    required this.sozlar,
    required this.darsId,
    required this.onDone,
    this.award,
  });

  @override
  State<BirlikKoplikAyt> createState() => _BirlikKoplikAytState();
}

class _BirlikKoplikAytState extends State<BirlikKoplikAyt> {
  late final List<QiroatVocab> _navbat = [...widget.sozlar];
  final Set<String> _qaytgan = {};
  bool _ochiq = false;

  QiroatVocab get _v => _navbat.first;
  String get _birlik => splitForms(_v.ar).first;

  Future<void> _och() async {
    setState(() => _ochiq = true);
    final v = _v;
    await Tts.instance.speak(_birlik, id: 'ayt');
    if (!mounted || !_ochiq || _navbat.isEmpty || !identical(v, _v)) return;
    if (v.plShakllari.isNotEmpty) {
      await Tts.instance.speak(v.plShakllari.first, id: 'ayt');
    }
  }

  Future<void> _baho(bool togri) async {
    final v = _v;
    await progress.bumpWord('${widget.darsId}::${v.ar}', togri);
    if (togri) widget.award?.call(1);
    if (!mounted) return;
    setState(() {
      _navbat.removeAt(0);
      if (!togri && _qaytgan.add(v.ar)) _navbat.add(v);
      _ochiq = false;
    });
    if (_navbat.isEmpty) widget.onDone();
  }

  Widget _shakl(String sarlavha, String ar, Color rang) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      children: [
        Text(
          sarlavha,
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.matn3,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpeakButton(text: ar, id: 'ayt-$ar', size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  ar,
                  textAlign: TextAlign.center,
                  style: AppTheme.arabic(
                    size: 36,
                    color: rang,
                    w: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_navbat.isEmpty) return const SizedBox.shrink();
    final v = _v;
    final bor = v.plShakllari.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
      child: Column(
        children: [
          Text(
            'Qoldi: ${_navbat.length}',
            style: TextStyle(fontSize: 12, color: AppColors.matn3),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      v.uz,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bor
                          ? "Birligi va ko'pligini ovoz chiqarib ayting"
                          : 'Arabchasini ovoz chiqarib ayting',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.matn2),
                    ),
                    const SizedBox(height: 22),
                    if (_ochiq) ...[
                      _shakl('BIRLIGI', _birlik, AppColors.ink),
                      for (final sh in v.plShakllari)
                        _shakl("KO'PLIGI", sh, AppColors.gold),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!_ochiq)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('ayt-och'),
                onPressed: _och,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  'Aytdim — tekshirish',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('ayt-xato'),
                    onPressed: () => _baho(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text('Adashdim'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('ayt-togri'),
                    onPressed: () => _baho(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text("To'g'ri aytdim"),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// To'liq dars sahifasidan ochiladigan ekran: darsning hamma so'zi.
class BirlikKoplikEkrani extends StatelessWidget {
  final QiroatLesson lesson;
  const BirlikKoplikEkrani({super.key, required this.lesson});

  static List<QiroatVocab> sozlar(QiroatLesson l) {
    final seen = <String>{};
    return [
      for (final v in l.vocab)
        if (v.ar.trim().isNotEmpty && v.uz.trim().isNotEmpty && seen.add(v.uz))
          v,
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Birligi va ko'pligi")),
    body: BirlikKoplikAyt(
      sozlar: sozlar(lesson),
      darsId: lesson.completionId,
      onDone: () => Navigator.pop(context),
    ),
  );
}
