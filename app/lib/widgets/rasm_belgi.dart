import 'package:flutter/material.dart';

import '../rasm.dart';
import '../theme.dart';

/// Konkret ot rasmi — yumshoq doira ichida katta emoji.
///
/// Rasm topilmasa hech nima chizilmaydi (bo'sh joy ham emas): matnli
/// kartalar bilan rasmli kartalar bir xil balandlikda turmaydi, lekin
/// bu «rasm yo'q» degan bo'sh doiradan yaxshi.
class RasmBelgi extends StatelessWidget {
  final String uz;
  final double olcham;
  const RasmBelgi({super.key, required this.uz, this.olcham = 64});

  @override
  Widget build(BuildContext context) {
    final r = Rasm.topish(uz);
    if (r == null) return const SizedBox.shrink();
    return Container(
      width: olcham,
      height: olcham,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.softGreen,
        shape: BoxShape.circle,
      ),
      child: Text(
        r,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: olcham * 0.52, height: 1),
      ),
    );
  }
}
