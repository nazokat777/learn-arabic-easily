import 'package:flutter/material.dart';

/// Ilova bo'ylab qisqa xabarlar (snackbar) — kontekstsiz joylardan ham
/// (masalan, ovoz xizmati) chaqirish uchun. MaterialApp'ga
/// `scaffoldMessengerKey: xabarKaliti` beriladi.
///
/// Nega kerak: xatolar jim o'tmasin. «Ovoz chiqmadi» holatida foydalanuvchi
/// ilovani buzilgan deb o'ylardi; endi sabab va nima qilish aytiladi.
final GlobalKey<ScaffoldMessengerState> xabarKaliti =
    GlobalKey<ScaffoldMessengerState>();

DateTime? _oxirgi;

/// Xabarni ko'rsatadi. Bir xil xabar 8 soniyada bir martadan ko'p chiqmaydi —
/// ketma-ket bosishlarda ekran to'lib ketmasin.
void xabarBer(String matn, {IconData ikon = Icons.info_outline_rounded}) {
  final hozir = DateTime.now();
  if (_oxirgi != null && hozir.difference(_oxirgi!).inSeconds < 8) return;
  _oxirgi = hozir;
  final m = xabarKaliti.currentState;
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          Icon(ikon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(matn)),
        ],
      ),
    ),
  );
}
