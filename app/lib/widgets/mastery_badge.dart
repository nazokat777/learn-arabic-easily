import 'package:flutter/material.dart';

import '../main.dart';
import '../theme.dart';

/// Darsning o'zlashtirish holatini ko'rsatuvchi kichik belgi.
///
/// Uch holat bor va ular ataylab farqlanadi:
///  * ✅ — dars testdan BITTA HAM xatosiz o'tilgan («o'zlashtirildi»);
///  * `72%` — urinilgan, lekin hali xatosiz o'tilmagan (eng yaxshi natija);
///  * hech narsa — hali test topshirilmagan.
///
/// Nega foiz ko'rsatiladi: «o'zlashtirilmadi» degan quruq belgi o'quvchiga
/// qancha qolganini aytmaydi va qo'lini sovutadi. Raqam esa «bir oz qoldi»
/// degan aniq signal beradi.
///
/// Vidjet [progress] ga o'zi obuna bo'ladi, shuning uchun uni ishlatuvchi
/// ekranni `AnimatedBuilder` ga o'rash shart emas — testdan qaytilganda
/// belgi o'zi yangilanadi.
class MasteryBadge extends StatelessWidget {
  final String lessonId;
  final double size;
  const MasteryBadge({super.key, required this.lessonId, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        if (progress.isMastered(lessonId)) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.check_circle,
                color: AppColors.success, size: size),
          );
        }
        if (progress.isUntried(lessonId)) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5), width: 1),
            ),
            child: Text('${progress.bestPercent(lessonId)}%',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.55,
                    color: AppColors.gold)),
          ),
        );
      },
    );
  }
}

/// Dars ekranining pastidagi «testga o'tish» chaqirig'i.
///
/// Matni holatga qarab o'zgaradi, chunki o'zlashtirgan o'quvchiga «darsni
/// mustahkamlang» deyish ma'nosiz — unga takrorlash taklif qilinadi.
class MasteryCallToAction extends StatelessWidget {
  final String lessonId;
  final VoidCallback onStart;

  /// Test nima ustidan olinishini aytuvchi qisqa izoh (masalan «dars
  /// qoidasi va misollari»).
  final String what;

  const MasteryCallToAction({
    super.key,
    required this.lessonId,
    required this.onStart,
    this.what = 'dars matni',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final mastered = progress.isMastered(lessonId);
        final untried = progress.isUntried(lessonId);
        final best = progress.bestPercent(lessonId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mastered ? AppColors.softGreen : AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(mastered ? '✅' : '🎯',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mastered
                          ? 'Bu dars o\'zlashtirilgan. Xohlasangiz yana '
                              'takrorlab ko\'ring.'
                          : untried
                              ? 'Dars «o\'zlashtirildi» belgisini olishi uchun '
                                  'testni bitta ham xatosiz o\'tish kerak.'
                              : 'Eng yaxshi natijangiz: $best%. Xatosiz '
                                  'o\'tsangiz, dars o\'zlashtirilgan bo\'ladi.',
                      style: const TextStyle(
                          fontSize: 13, height: 1.35, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    mastered ? AppColors.gold : AppColors.emerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onStart,
              icon: Text(mastered ? '🔁' : '🎯',
                  style: const TextStyle(fontSize: 18)),
              label: Text(
                  mastered
                      ? 'Yana takrorlash'
                      : 'Testni boshlash — $what',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ],
        );
      },
    );
  }
}
