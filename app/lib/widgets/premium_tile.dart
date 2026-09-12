import 'package:flutter/material.dart' hide Text;
import 'uz_text.dart';

import '../theme.dart';
import 'motion.dart';

/// Ichki ekranlar uchun bitta umumiy ro'yxat kartochkasi.
///
/// Nega kerak: bosh ekran premium chizilgandan keyin ichki ekranlarning
/// yassi oq kartochkalari «boshqa ilova»dek tuyulardi. Bitta vidjet —
/// hamma joyda bitta ko'rinish: rangli soya, gradient ikonka tilesi,
/// bosish hissi, o'ngda dumaloq strelka.
///
/// Emoji ishlatilmaydi: u qurilmaga qarab har xil chiqadi (Windows'da
/// umuman bo'sh kvadrat). O'rniga Material ikonkasi yoki arabcha harf.
class PremiumTile extends StatelessWidget {
  final String title;
  final String subtitle;

  /// Arabcha izoh — sarlavha ostida, Amiri shriftida va o'ngdan chapga.
  ///
  /// Nega alohida slot: dars sarlavhalari arabcha keladi va ularni oddiy
  /// [subtitle] ga qo'ysak, Nunito shriftida chiziladi — harakatlar
  /// harfdan ajralib, so'z ustida suzib qoladi.
  final String? arabicSubtitle;

  /// Ikonka tilesida ko'rsatiladigan narsa — uchalasidan bittasi.
  /// [label] — oddiy matn (masalan kitob raqami), Nunito shriftida.
  final IconData? icon;
  final String? arabic;
  final String? label;

  final Color accent;
  final VoidCallback? onTap;

  /// Strelkadan oldin turadigan qo'shimcha (masalan o'zlashtirish belgisi).
  final Widget? trailing;

  final bool enabled;

  const PremiumTile({
    super.key,
    required this.title,
    this.subtitle = '',
    this.arabicSubtitle,
    this.icon,
    this.arabic,
    this.label,
    this.accent = AppColors.emerald,
    this.onTap,
    this.trailing,
    this.enabled = true,
  }) : assert(
         icon != null || arabic != null || label != null,
         'icon, arabic yoki label kerak',
       );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final dark = Color.lerp(accent, Colors.black, 0.28)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Tactile(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: enabled ? 0.13 : 0.04),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: AppColors.karta,
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                onTap: enabled ? onTap : null,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accent, dark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: arabic != null
                              ? Text(
                                  arabic!,
                                  style: AppTheme.arabic(
                                    size: 22,
                                    color: AppColors.karta,
                                    w: FontWeight.w700,
                                  ),
                                )
                              : label != null
                              ? Text(
                                  label!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                  ),
                                )
                              : Icon(icon, color: Colors.white, size: 26),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: AppColors.ink,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (arabicSubtitle != null) ...[
                              const SizedBox(height: 2),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  arabicSubtitle!,
                                  style: AppTheme.arabic(
                                    size: 17,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: AppColors.matn2,
                                  fontSize: 12.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null) trailing!,
                      const SizedBox(width: 4),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
