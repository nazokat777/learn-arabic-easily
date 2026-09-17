import 'package:flutter/material.dart' hide Text;

import '../harflab.dart';
import '../services/tts.dart';
import '../theme.dart';
import 'entrance.dart';
import 'uz_text.dart';

/// So'zning harflari qatori: har harf bosilsa NOMI aytiladi (inson ovozi),
/// «Harflab tinglash» tugmasi hammasini ketma-ket aytib, oxirida so'zning
/// o'zini o'qiydi — xuddi ustoz doskada «sin, ba, vov, ro, ta marbuta —
/// sabbura» deb aytgandek.
///
/// Nega: harflarni ayrim-ayrim tanish bilan so'zni butun o'qish orasidagi
/// ko'prik shu — harflab aytish. O'qishni endi boshlagan o'quvchi so'zni
/// harflab «yechadi», keyin qo'shib o'qiydi.
class HarflabQatori extends StatefulWidget {
  final String soz;

  /// Ovoz id'lari to'qnashmasligi uchun (bir sahifada bir nechta qator).
  final String id;
  final double harfOlchami;
  const HarflabQatori({
    super.key,
    required this.soz,
    required this.id,
    this.harfOlchami = 24,
  });

  @override
  State<HarflabQatori> createState() => _HarflabQatoriState();
}

class _HarflabQatoriState extends State<HarflabQatori> {
  late final List<HarfBolagi> _harflar = harflab(widget.soz);
  int _faol = -1; // hozir aytilayotgan harf
  bool _ketmoqda = false;

  @override
  void dispose() {
    _ketmoqda = false;
    super.dispose();
  }

  Future<void> _hammasi() async {
    if (_ketmoqda) {
      setState(() {
        _ketmoqda = false;
        _faol = -1;
      });
      await Tts.instance.stop();
      return;
    }
    setState(() => _ketmoqda = true);
    for (var i = 0; i < _harflar.length; i++) {
      if (!mounted || !_ketmoqda) return;
      setState(() => _faol = i);
      await Tts.instance.speak(_harflar[i].nom, id: '${widget.id}-h$i');
    }
    if (!mounted || !_ketmoqda) return;
    setState(() => _faol = -1);
    await Tts.instance.speak(widget.soz, id: '${widget.id}-soz');
    if (mounted) setState(() => _ketmoqda = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_harflar.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          textDirection: TextDirection.rtl,
          children: [
            for (var i = 0; i < _harflar.length; i++)
              PressableScale(
                child: Material(
                  color: _faol == i ? AppColors.gold : AppColors.softGreen,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() => _faol = i);
                      Tts.instance
                          .speak(_harflar[i].nom, id: '${widget.id}-h$i')
                          .whenComplete(() {
                            if (mounted && _faol == i && !_ketmoqda) {
                              setState(() => _faol = -1);
                            }
                          });
                    },
                    child: Container(
                      width: widget.harfOlchami + 16,
                      height: widget.harfOlchami + 20,
                      alignment: Alignment.center,
                      child: Text(
                        _harflar[i].harf,
                        style: AppTheme.arabic(
                          size: widget.harfOlchami,
                          color: _faol == i
                              ? Colors.white
                              : AppColors.zumradMatn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _hammasi,
          style: TextButton.styleFrom(
            foregroundColor: _ketmoqda ? AppColors.gold : AppColors.emerald,
            padding: EdgeInsets.zero,
          ),
          icon: Icon(
            _ketmoqda ? Icons.stop_circle_rounded : Icons.spellcheck_rounded,
            size: 20,
          ),
          label: Text(
            _ketmoqda ? "To'xtatish" : 'Harflab tinglash',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
