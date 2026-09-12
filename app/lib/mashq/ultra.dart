import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import '../widgets/uz_text.dart';
import 'mukofot.dart';

/// «Ultra» mukofot qatlami: kutish, kutilmagan sovg'a, rekord, kombo nuri.
///
/// Neyrobiologik asos: dofamin MUKOFOTDA emas, mukofotni KUTISHDA eng
/// baland ko'tariladi. Shuning uchun sandiq avval titraydi, keyin
/// ochiladi; ichidagi son noma'lum. Rekordni yangilash — o'zi bilan
/// musobaqa, tashqi baholashsiz eng barqaror motivatsiya. Kombo nuri —
/// «seriyani uzmaslik» istagi: yo'qotishdan qo'rqish yutuqdan kuchliroq.

/// Xazina sandig'i — mukammal raund uchun kutilmagan bonus.
///
/// Bosilguncha yopiq turadi va sekin tebranadi (kutish); bosilganda
/// sakraydi, portlaydi va bonus soni sanab chiqadi. Bonus miqdori har
/// safar boshqacha — aynan noaniqlik uni qimmatli qiladi.
class XazinaSandigi extends StatefulWidget {
  final int bonus;
  final VoidCallback onOchildi;
  const XazinaSandigi({
    super.key,
    required this.bonus,
    required this.onOchildi,
  });

  /// Tasodifiy bonus: ko'pincha kichik, ba'zan katta — o'zgaruvchan mukofot.
  static int tasodifiyBonus(Random rnd) {
    final r = rnd.nextInt(100);
    if (r < 55) return 5;
    if (r < 85) return 10;
    if (r < 97) return 20;
    return 50;
  }

  @override
  State<XazinaSandigi> createState() => _XazinaSandigiState();
}

class _XazinaSandigiState extends State<XazinaSandigi>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _ochildi = false;
  int _portlash = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _och() {
    if (_ochildi) return;
    Haptic.ok();
    setState(() {
      _ochildi = true;
      _portlash++;
    });
    _c.forward(from: 0);
    widget.onOchildi();
  }

  @override
  Widget build(BuildContext context) {
    return Portlash(
      trigger: _portlash == 0 ? null : _portlash,
      ranglar: const [AppColors.gold, AppColors.goldLight, AppColors.amber],
      child: GestureDetector(
        onTap: _och,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final sakrash = _ochildi
                ? Curves.elasticOut.transform(_c.value)
                : 0.0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 1 + 0.25 * sakrash,
                  child: _ochildi
                      ? const Icon(
                          Icons.workspace_premium_rounded,
                          size: 64,
                          color: AppColors.gold,
                        )
                      : Float(
                          amplitude: 3,
                          child: Container(
                            width: 76,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.gold, AppColors.amber],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.5),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                _ochildi
                    ? CountUp(
                        value: widget.bonus,
                        suffix: ' ball!',
                        duration: const Duration(milliseconds: 900),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                        ),
                      )
                    : const Text(
                        "Sandiqni oching — ichida sovg'a bor",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Kombo nuri — seriya 5 dan oshganda savol kartasi atrofida nafas
/// oluvchi nur; 10 dan oshganda oltin rangga o'tadi.
class KomboNur extends StatefulWidget {
  final int ketmaKet;
  final Widget child;
  const KomboNur({super.key, required this.ketmaKet, required this.child});

  @override
  State<KomboNur> createState() => _KomboNurState();
}

class _KomboNurState extends State<KomboNur>
    with SingleTickerProviderStateMixin {
  // Darhol yaratiladi: `late` bo'lsa, nur hech chiqmagan ekranda dispose
  // paytida yaratilib, o'chirilgan daraxtdan TickerMode qidirardi.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daraja = widget.ketmaKet >= 10 ? 2 : (widget.ketmaKet >= 5 ? 1 : 0);
    if (daraja == 0) return widget.child;
    final rang = daraja == 2 ? AppColors.gold : AppColors.coral;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: rang.withValues(alpha: 0.25 + 0.35 * t),
                blurRadius: 18 + 16 * t,
                spreadRadius: 1 + 3 * t,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// Kombo marrasi — keyingi bosqichgacha nechta qoldi (3 → 5 → 10).
///
/// Marraga yaqinlashganda odam tezlashadi («goal gradient»); shuning
/// uchun keyingi marra doim ko'rinib turadi: «5-komboga 2 ta qoldi».
class KomboMarra extends StatelessWidget {
  final int ketmaKet;
  const KomboMarra({super.key, required this.ketmaKet});

  static const _marralar = [3, 5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    if (ketmaKet == 0) return const SizedBox.shrink();
    final keyingi = _marralar.firstWhere(
      (m) => m > ketmaKet,
      orElse: () => ((ketmaKet ~/ 10) + 1) * 10,
    );
    final qoldi = keyingi - ketmaKet;
    return Text(
      qoldi == 1
          ? '$keyingi-komboga 1 ta qoldi!'
          : '$keyingi-komboga $qoldi ta qoldi',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: qoldi == 1 ? AppColors.coral : Colors.black45,
      ),
    );
  }
}

/// Daraja oshganda BUTUN EKRANNI egallaydigan lahza.
///
/// Banner e'tibordan chetda qolishi mumkin; daraja esa kam bo'ladigan
/// katta voqea — unga to'liq sahna kerak: nur halqasi, konfetti va
/// o'quvchi o'zi yopadigan tugma (o'zi yopgan lahza esda qoladi).
Future<void> darajaOynasi(
  BuildContext context, {
  required String nom,
  required int daraja,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'daraja',
    barrierColor: AppColors.deep.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 420),
    transitionBuilder: (context, a, _, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: child,
      ),
    ),
    pageBuilder: (context, _, _) => Stack(
      children: [
        const Positioned.fill(child: Confetti(count: 140)),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(28),
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GlowRing(
                    size: 128,
                    child: Float(
                      amplitude: 4,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 64,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Yangi daraja!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nom,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    "$daraja-pog'ona",
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Davom etamiz!',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
