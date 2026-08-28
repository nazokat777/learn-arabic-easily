import 'package:flutter/material.dart';

import '../services/tts.dart';
import '../theme.dart';

/// Kichik dumaloq ovoz tugmasi. O'qilayotganda belgisi «to'xtat»ga o'zgaradi,
/// shunda foydalanuvchi qaysi qator gapirayotganini ko'rib turadi.
///
/// Tugma har doim ko'rinadi: ovoz tayyor fayldan chiqadi, qurilma TTS'i
/// ishlamasa ham.
class SpeakButton extends StatelessWidget {
  final String text;
  final String id;
  final double size;

  /// Boshqacha belgi kerak bo'lganda (masalan lug'atdagi «jumlada tinglash»).
  final IconData? icon;
  final String? tooltip;
  const SpeakButton({
    super.key,
    required this.text,
    required this.id,
    this.size = 20,
    this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: Tts.instance.speakingId,
      builder: (context, speaking, _) {
        final active = speaking == id;
        return IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: size + 16, height: size + 16),
          tooltip: active ? 'To\'xtatish' : 'Tinglash',
          icon: Icon(active ? Icons.stop_circle : (icon ?? Icons.volume_up_rounded),
              size: size, color: active ? AppColors.gold : AppColors.emerald),
          onPressed: () {
            if (active) {
              Tts.instance.stop();
              return;
            }
            Tts.instance.speak(text, id: id);
          },
        );
      },
    );
  }
}
