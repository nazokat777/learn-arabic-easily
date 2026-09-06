import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';

import '../lugat.dart';
import '../screens/lesson/word_sheet.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../uz_yozuv.dart';

/// O'zbekcha matn ichida arabcha so'zlar kelganda ishlatiladi.
///
/// Nega kerak: sarf kitobining matni o'zbekcha, arabcha misollar esa gap
/// ichida keladi («Masalan: ضَرَبَ vaznida»). Butun satrni oddiy `Text`
/// bilan chizsak, arabcha qism Nunito shriftida chiziladi va harakatlar
/// harfdan ajralib, o'qib bo'lmaydigan bo'lib qoladi. Shuning uchun satr
/// bo'laklarga bo'linadi: arabcha bo'laklar Amiri bilan, qolgani
/// o'zbekcha shrift bilan chiziladi.
///
/// Arabcha so'zga bosilsa — ma'nosi chiqadi (topilsa), aks holda o'qib
/// beriladi. Bu qiroat va nahv darslaridagi xatti-harakat bilan bir xil.
class AralashMatn extends StatelessWidget {
  final String matn;
  final TextStyle uslub;
  final double arabchaOlchami;

  const AralashMatn(
    this.matn, {
    super.key,
    this.uslub = const TextStyle(fontSize: 15, height: 1.55),
    this.arabchaOlchami = 22,
  });

  /// Arabcha harflar oralig'i (harakat va tinish belgilari bilan).
  static final _arabcha = RegExp(r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');

  static bool _arabchami(String c) => _arabcha.hasMatch(c);

  @override
  Widget build(BuildContext context) {
    // Matnni arabcha va o'zbekcha bo'laklarga ajratamiz. Arabcha bo'lakka
    // yopishgan bo'sh joy va tinish belgilari ham o'sha bo'lakda qoladi —
    // aks holda so'z va vergul orasi uzilib ko'rinadi.
    final bolaklar = <({String matn, bool arab})>[];
    var joriy = StringBuffer();
    bool? holat;
    for (final c in matn.characters) {
      final a = _arabchami(c);
      if (holat == null) {
        holat = a;
      } else if (a != holat) {
        // Bo'sh joyni chegara qilib qoldiramiz: qaysi tomonga qo'shilsa ham
        // ko'rinishi bir xil, lekin bo'lak almashuvi kamayadi.
        if (c == ' ' || c == ' ') {
          joriy.write(c);
          continue;
        }
        bolaklar.add((matn: joriy.toString(), arab: holat));
        joriy = StringBuffer();
        holat = a;
      }
      joriy.write(c);
    }
    if (joriy.isNotEmpty) {
      bolaklar.add((matn: joriy.toString(), arab: holat ?? false));
    }

    final span = <InlineSpan>[];
    for (final b in bolaklar) {
      if (!b.arab) {
        span.add(TextSpan(text: uz(b.matn), style: uslub));
        continue;
      }
      span.add(
        TextSpan(
          text: b.matn,
          style: AppTheme.arabic(
            size: arabchaOlchami,
            color: AppColors.emeraldDark,
            w: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _bosildi(context, b.matn),
        ),
      );
    }
    return m.Text.rich(TextSpan(children: span));
  }

  void _bosildi(BuildContext context, String bolak) {
    final soz = bolak.trim();
    if (soz.isEmpty) return;
    final topilma = Lugat.instance.qidir(soz);
    if (topilma != null) {
      showWordSheet(context, topilma.soz, bosilgan: topilma.aynan ? null : soz);
    } else {
      Tts.instance.speak(soz, id: soz);
    }
  }
}
