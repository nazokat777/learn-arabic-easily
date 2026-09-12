import 'package:flutter/material.dart' hide Text;

import '../main.dart';
import '../progress.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import '../widgets/uz_text.dart';

/// Tanishuv — birinchi ochilishda bir marta, uch qadam.
///
/// Nega: yangi foydalanuvchi bo'sh ekranda («0 ball», «seriya boshlang»)
/// nima qilishni bilmay qoladi. Uch jumla bilan o'yin qoidasi tushuntiriladi:
/// har kuni 20 savol → olov yonadi → nishonlar ochiladi. Aniq va yaqin
/// maqsad birinchi kundanoq bor.
Future<void> tanishuvniKorsat(BuildContext context) async {
  if (progress.tanishuvKurildi) return;
  await progress.tanishuvniBelgila();
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'tanishuv',
    barrierColor: AppColors.deep.withValues(alpha: 0.8),
    transitionDuration: const Duration(milliseconds: 420),
    transitionBuilder: (context, a, _, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: child,
      ),
    ),
    pageBuilder: (context, _, _) => const _Tanishuv(),
  );
}

class _Tanishuv extends StatefulWidget {
  const _Tanishuv();

  @override
  State<_Tanishuv> createState() => _TanishuvState();
}

class _TanishuvState extends State<_Tanishuv> {
  int _qadam = 0;

  static const _qadamlar = <(IconData, Color, String, String)>[
    (
      Icons.track_changes_rounded,
      AppColors.coral,
      'Har kuni ${Progress.kunlikMaqsad} ta savol',
      "Bitta mashq — 2-3 raund. Shu yetadi: kunlik maqsad bajariladi, "
          "olov yonadi. Kam, lekin har kuni — tilni shunday o'rganadilar.",
    ),
    (
      Icons.local_fire_department_rounded,
      AppColors.amber,
      'Olov va sandiq',
      "Ketma-ket kunlar olovni o'stiradi. Har kuni bitta sandiq — ichida "
          "tasodifiy sovg'a, seriya uzun bo'lsa sovg'a kattaroq. Bir kun "
          "o'tkazib yuborsangiz, himoya olovni saqlab qoladi.",
    ),
    (
      Icons.emoji_events_rounded,
      AppColors.gold,
      'Nishonlar va darajalar',
      "Har to'g'ri javob ball beradi, har 100 ball — yangi daraja. Yo'lda "
          "19 ta nishon ochiladi. Qiynalgan so'zlarni ilova o'zi eslab, "
          "qayta so'raydi — hech narsa unutilmaydi.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final (ikon, rang, sarlavha, matn) = _qadamlar[_qadam];
    final oxirgi = _qadam == _qadamlar.length - 1;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 22),
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: AppColors.karta,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: Column(
                  key: ValueKey(_qadam),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlowRing(
                      size: 116,
                      color: rang,
                      child: Float(
                        amplitude: 4,
                        child: Icon(ikon, size: 54, color: rang),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      sarlavha,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      matn,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.matn2,
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _qadamlar.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _qadam ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _qadam ? rang : AppColors.chiziq,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Haptic.tap();
                    if (oxirgi) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _qadam++);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: rang,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    oxirgi ? 'Boshladik!' : 'Keyingisi',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (!oxirgi)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "O'tkazib yuborish",
                    style: TextStyle(
                      color: AppColors.matn3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
