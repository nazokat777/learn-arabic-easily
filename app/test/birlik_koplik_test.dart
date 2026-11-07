// «Birligi va ko'pligini ayting»: javob ochilguncha yashirin, adashilgan so'z
// navbat oxirida bir marta qaytadi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/lesson/birlik_koplik.dart';

void main() {
  progress = Progress();

  testWidgets("ochiladi, adashilgani qaytadi, oxirida tugaydi", (t) async {
    var tugadi = false;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BirlikKoplikAyt(
            sozlar: const [
              QiroatVocab(ar: 'بَيْتٌ', pl: 'بُيُوتٌ', uz: 'uy'),
              QiroatVocab(ar: 'قَلَمٌ', pl: '', uz: 'qalam'),
            ],
            darsId: 'sinov-ayt',
            onDone: () => tugadi = true,
          ),
        ),
      ),
    );
    Future<void> bos(String k) async {
      await t.tap(find.byKey(ValueKey(k)));
      await t.pump();
      await t.pump();
    }

    expect(find.text('uy'), findsOneWidget);
    expect(find.text('بُيُوتٌ'), findsNothing);
    await bos('ayt-och');
    expect(find.text('بُيُوتٌ'), findsOneWidget);
    await bos('ayt-xato');
    expect(find.text('qalam'), findsOneWidget);
    await bos('ayt-och');
    await bos('ayt-togri');
    expect(find.text('uy'), findsOneWidget);
    await bos('ayt-och');
    await bos('ayt-togri');
    expect(tugadi, isTrue);
  });
}
