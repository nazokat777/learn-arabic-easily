// Bosh ekrandagi har bir bo'lim kartochkasi CHINDAN bosiladimi.
//
// Nega kerak: kartochka ko'rinib turgani bilan bosilmasligi mumkin —
// ustidagi bezak qatlami (naqsh, yorug'lik) bosishni yutib yuboradi.
// Bu ilgari yozuv tugmasida bo'lgan va faqat brauzerda qo'lda bosib
// ko'rilganda aniqlangan edi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/home.dart';

void main() {
  progress = Progress();
  repo = ContentRepository();

  Future<void> ochish(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    // Kirish animatsiyalari tugasin (pumpAndSettle ishlamaydi: fonda
    // to'xtovsiz aylanadigan bezaklar bor).
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  for (final nom in const [
    'Alifbo (Harflar)',
    'Mabdaul qiroat',
    'Nahv',
    'Sarf',
  ]) {
    testWidgets('«$nom» kartochkasi bosiladi', (tester) async {
      await ochish(tester);

      final karta = find
          .text(nom)
          .last; // tez yo'l chipi ham bor, karta keyin keladi
      expect(find.text(nom), findsWidgets, reason: 'kartochka ko\'rinmadi');

      await tester.ensureVisible(karta);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(karta, warnIfMissed: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Yangi ekran ochilgan bo'lsa, orqaga qaytish tugmasi paydo bo'ladi.
      expect(
        find.byType(BackButton),
        findsWidgets,
        reason: '«$nom» bosilganda hech narsa ochilmadi',
      );
    });
  }
}
