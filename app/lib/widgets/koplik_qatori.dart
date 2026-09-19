import 'package:flutter/material.dart' hide Text;

import '../content.dart';
import '../theme.dart';
import 'speak_button.dart';
import 'uz_text.dart';

/// So'zning KO'PLIGI — kitobda («Mabdaul qiroat») deyarli har ot birlik +
/// ko'plik juftligi bilan berilgan; mashq va testlarda birlikni ko'rsatib,
/// ko'plikni yashirish kitobning yarmini tashlab ketish edi.
///
/// Har ko'plik shakli o'z ovoz tugmasi bilan («=» / «،» bilan ajratilgan
/// bir nechta shakl bo'lishi mumkin). Ko'plik bo'lmasa — hech narsa chizmaydi.
class KoplikQatori extends StatelessWidget {
  final QiroatVocab v;
  final double size;
  final String idPrefix;
  const KoplikQatori({
    super.key,
    required this.v,
    this.size = 20,
    this.idPrefix = 'kop',
  });

  @override
  Widget build(BuildContext context) {
    if (v.pl.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            "ko'pligi:",
            style: TextStyle(fontSize: 12.5, color: AppColors.matn3),
          ),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              v.pl,
              style: AppTheme.arabic(
                size: size,
                color: AppColors.gold,
                w: FontWeight.w600,
              ),
            ),
          ),
          for (final sh in v.plShakllari)
            SpeakButton(text: sh, id: '$idPrefix-$sh', size: 15),
        ],
      ),
    );
  }
}
