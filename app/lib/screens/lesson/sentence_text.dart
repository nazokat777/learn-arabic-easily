import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../arabic.dart';
import '../../content.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import 'word_sheet.dart';

/// Bir o'qish jumlasi — har bir arabcha so'z bosiladigan.
/// So'zga bosilsa: lug'atda topilsa — interaktiv karta; aks holda — audio.
class SentenceText extends StatelessWidget {
  final String sentence;
  final List<QiroatVocab> vocab; // shu darsning lug'ati (so'z izlash uchun)
  final String reading; // misol jumla uchun
  final double size;
  final Color color;

  const SentenceText({
    super.key,
    required this.sentence,
    required this.vocab,
    required this.reading,
    this.size = 26,
    this.color = AppColors.ink,
  });

  QiroatVocab? _lookup(String word) {
    final w = stripDiacritics(word);
    if (w.length < 2) return null;
    QiroatVocab? best;
    int bestLen = 0;
    for (final v in vocab) {
      for (final f in splitForms(v.ar)) {
        final n = stripDiacritics(f);
        if (n.length < 3) continue;
        if (w == n || w.contains(n) || n.contains(w)) {
          if (n.length > bestLen) {
            best = v;
            bestLen = n.length;
          }
        }
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = tokenize(sentence);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(
          children: tokens.map((t) {
            if (!t.isWord) {
              return TextSpan(text: t.text, style: AppTheme.arabic(size: size, color: color));
            }
            final v = _lookup(t.text);
            return TextSpan(
              text: t.text,
              style: AppTheme.arabic(
                size: size,
                color: v != null ? AppColors.emeraldDark : color,
                w: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  if (v != null) {
                    showWordSheet(context, v, reading: reading);
                  } else {
                    Tts.instance.speak(t.text, id: t.text);
                  }
                },
            );
          }).toList(),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
      ),
    );
  }
}
