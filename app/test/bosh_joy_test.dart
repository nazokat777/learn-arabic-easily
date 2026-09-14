// «Bo'sh joy»: kitob jumlasidan lug'at so'zi olib tashlanadi; variantlar
// shu darsning boshqa so'zlari; to'g'ri javob +2, jumla o'qiladi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/arabic.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/bosh_joy.dart';

void main() {
  progress = Progress();
  final raw = File('assets/content/qiroat_lessons.json').readAsStringSync();
  final darslar = (json.decode(raw)['lessons'] as List)
      .map((e) => QiroatLesson.fromJson(e as Map<String, dynamic>))
      .toList();
  repo = ContentRepository()..qiroatLessons = darslar;

  test("topshiriqlar matndan: so'z jumlada aynan, ko'p darsda ≥3 ta", () {
    var bor = 0;
    for (final l in darslar) {
      final t = BoshJoy.yasa(l);
      if (t.length >= 3) bor++;
      for (final b in t) {
        // oldi + so'z + keyin = jumla (hech narsa yo'qolmaydi).
        expect(b.oldi + b.soz + b.keyin, b.jumla);
        expect(stripDiacritics(b.soz).length, greaterThanOrEqualTo(2));
      }
      // Bir jumla ikki marta ishlatilmaydi.
      expect(t.map((b) => b.jumla).toSet().length, t.length);
    }
    // ignore: avoid_print
    print("bo'sh joy bor darslar: $bor / ${darslar.length}");
    expect(bor, greaterThan(darslar.length ~/ 2));
  });

  testWidgets("ekran: to'g'ri javob +2, keyingi, yakun", (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final l = darslar.firstWhere((l) => BoshJoy.yasa(l).length >= 3);
    final n = BoshJoy.yasa(l).length;
    final oldin = progress.xp;
    await tester.pumpWidget(MaterialApp(home: BoshJoyEkrani(lesson: l)));
    await tester.pump();
    expect(find.text('1 / $n'), findsOneWidget);
    expect(find.text("Jumladagi bo'sh joyga qaysi so'z tushadi?"), findsOneWidget);
    // Ekrandagi variantlardan to'g'risini topamiz: ma'no yozuvidan.
    final manoMatn = tester
        .widget<Text>(find.textContaining("ma'nosidagi so'z"))
        .data!;
    final uz = manoMatn.substring(1, manoMatn.indexOf('»'));
    final togri = BoshJoy.yasa(l).firstWhere((b) => b.lugat.uz == uz);
    // Bir nechta topshiriqda bir xil lug'at bo'lishi mumkin — so'z shakli
    // bo'yicha ham tekshiramiz: variantlar ichida bor.
    expect(find.text(togri.soz), findsWidgets);
    await tester.tap(find.text(togri.soz).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(progress.xp - oldin, 2);
    expect(find.text('Keyingi'), findsOneWidget);
  });
}
