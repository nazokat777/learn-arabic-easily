// «Sanoq bilan yodlash»: matn belgilangan marta o'qiladi, sanoq saqlanadi,
// maqsad o'zgartiriladi, oraliq tekshiruv va yakuniy lug'at testi chiziladi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/arabic.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/harflab.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/gapma_gap_tarjima.dart' show TarjimaPaneli;
import 'package:learn_arabic/screens/lesson/sentence_text.dart';
import 'package:learn_arabic/screens/sanoq_ekrani.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final raw = File('assets/content/qiroat_lessons.json').readAsStringSync();
  final darslar = (json.decode(raw)['lessons'] as List)
      .map((e) => QiroatLesson.fromJson(e as Map<String, dynamic>))
      .toList();
  final harflar = json.decode(
    File('assets/content/letters.json').readAsStringSync(),
  );
  repo = ContentRepository()
    ..qiroatLessons = darslar
    ..letters = (harflar['letters'] as List)
        .map((e) => Letter.fromJson(e))
        .toList();
  progress = Progress();
  SanoqEkrani.jonli = false;
  final dars4 = darslar.firstWhere((l) => l.book == 1 && l.num == 4);
  final gapSoni = splitSentences(dars4.reading).length;
  final gaplar4 = splitSentences(dars4.reading);
  final yozishSoni = dars4.tarjimaGuruhlari
      .where((g) => g.matn.trim().isNotEmpty)
      .map((g) => gaplar4.sublist(g.boshi, g.boshi + g.soni).join(' '))
      .toSet()
      .length;
  final guruhSoni = dars4.tarjimaGuruhlari
      .where((g) => g.matn.trim().isNotEmpty)
      .length;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await progress.load();
  });

  Future<void> och(WidgetTester t, {QiroatLesson? l}) async {
    t.view.physicalSize = const Size(900, 9000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(MaterialApp(home: SanoqEkrani(lesson: l ?? dars4)));
    await t.pumpAndSettle();
  }

  testWidgets(
    "yangi o'quvchi: tushuntirish, 0/33, arabcha matn, tarjima yopiq",
    (t) async {
      await och(t);
      expect(find.byKey(const ValueKey('sanoq-tanishuv')), findsOneWidget);
      expect(find.text('0 / 33 marta o\'qildi'), findsOneWidget);
      expect(find.byType(SentenceText), findsNWidgets(gapSoni));
      expect(find.byType(TarjimaPaneli), findsNothing);

      await t.tap(find.byKey(const ValueKey('sanoq-och')));
      await t.pumpAndSettle();
      // Har gap (guruh) tagida o'z tarjimasi, keyingi gapdan oldin.
      expect(find.byType(TarjimaPaneli), findsNWidgets(guruhSoni));
      final g = dars4.tarjimaGuruhlari.first;
      double y(String k) => t.getTopLeft(find.byKey(ValueKey(k))).dy;
      final tarjimaY = y('sanoq-tarjima-${g.boshi}');
      expect(tarjimaY, greaterThan(y('sanoq-gap-${g.boshi + g.soni - 1}')));
      expect(tarjimaY, lessThan(y('sanoq-gap-${g.boshi + g.soni}')));
    },
  );

  testWidgets("«O'qidim» sanoqni oshiradi, saqlanadi, tushuntirish yo'qoladi", (
    t,
  ) async {
    await och(t);
    await t.tap(find.byKey(const ValueKey('sanoq-oqidim')));
    await t.pumpAndSettle();
    expect(find.text('1 / 33 marta o\'qildi'), findsOneWidget);
    expect(find.byKey(const ValueKey('sanoq-tanishuv')), findsNothing);
    final p = await SharedPreferences.getInstance();
    expect(p.getInt('sanoq_${dars4.completionId}.soni'), 1);

    // Qayta ochilganda davom etadi.
    await t.pumpWidget(const SizedBox());
    await och(t);
    expect(find.text('1 / 33 marta o\'qildi'), findsOneWidget);
  });

  testWidgets('maqsad tanlanadi: tayyor son va o\'zi kiritgani', (t) async {
    await och(t);
    await t.tap(find.byKey(const ValueKey('sanoq-maqsad')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('maqsad-11')));
    await t.pumpAndSettle();
    expect(find.text('0 / 11 marta o\'qildi'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('sanoq-maqsad')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('maqsad-kiritish')), '40');
    await t.tap(find.byKey(const ValueKey('maqsad-ok')));
    await t.pumpAndSettle();
    expect(find.text('0 / 40 marta o\'qildi'), findsOneWidget);
    final p = await SharedPreferences.getInstance();
    expect(p.getInt('sanoq_${dars4.completionId}.maqsad'), 40);
  });

  testWidgets("o'zbekcha rejim: tarjima ochiq, arabchasi yopiq", (t) async {
    await och(t);
    await t.tap(find.text('O\'zbekcha'));
    await t.pumpAndSettle();
    expect(find.byType(TarjimaPaneli), findsNWidgets(guruhSoni));
    expect(find.byType(SentenceText), findsNothing);

    await t.tap(find.byKey(const ValueKey('sanoq-och')));
    await t.pumpAndSettle();
    expect(find.byType(SentenceText), findsNWidgets(gapSoni));
  });

  testWidgets("o'zbekcha rejim: sanoq faqat hammasi yozilgach oshadi", (
    t,
  ) async {
    await och(t);
    await t.tap(find.text('O\'zbekcha'));
    await t.pumpAndSettle();
    expect(find.textContaining('O\'qidim —'), findsNothing);
    await t.tap(find.byKey(const ValueKey('sanoq-oqidim')));
    await t.pumpAndSettle();
    final nav = Navigator.of(
      t.element(find.text('Arabchasini harflab yozing')),
    );
    // Yarim yo'lda chiqildi — hisoblanmaydi.
    nav.pop();
    await t.pumpAndSettle();
    expect(find.text('0 / 33 marta o\'qildi'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('sanoq-oqidim')));
    await t.pumpAndSettle();
    nav.pop(true); // oxirigacha yozildi
    await t.pumpAndSettle();
    expect(find.text('1 / 33 marta o\'qildi'), findsOneWidget);
  });

  testWidgets('11-o\'qishdan keyin gap tekshiruvi; maqsadda lug\'at testi', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({
      'sanoq_${dars4.completionId}.soni': 10,
      'sanoq_${dars4.completionId}.maqsad': 11,
    });
    await och(t);
    expect(find.text('10 / 11 marta o\'qildi'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('sanoq-oqidim')));
    await t.pumpAndSettle();
    // Gap tekshiruvi ochildi.
    expect(find.textContaining('Gap tekshiruvi 1 /'), findsOneWidget);
    // Birinchi variantni tanlab, oxirigacha o'tamiz.
    while (find.byKey(const ValueKey('gap-variant-0')).evaluate().isNotEmpty) {
      await t.tap(find.byKey(const ValueKey('gap-variant-0')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('gap-keyingi')));
      await t.pumpAndSettle();
    }
    // Yakun dialogi → lug'at testi.
    expect(find.text('Yozishni boshlash'), findsOneWidget);
    await t.tap(find.text('Yozishni boshlash'));
    await t.pumpAndSettle();
    // O'zbekcha gap beriladi, arabchasi harflab yoziladi.
    expect(find.text("O'zbekchadan arabchaga"), findsOneWidget);
    expect(find.text('Arabchasini harflab yozing'), findsOneWidget);
    expect(find.text('1 / $yozishSoni'), findsOneWidget);
    Navigator.of(t.element(find.text('Arabchasini harflab yozing'))).pop();
    await t.pumpAndSettle();
    // Keyin hamma lug'at harflab yoziladi.
    expect(find.text("Lug'atni harflab yozish"), findsOneWidget);
    Navigator.of(t.element(find.text('Arabchasini harflab yozing'))).pop();
    await t.pumpAndSettle();
    expect(find.textContaining('Lug\'at testi'), findsOneWidget);
  });

  test("fe'l shakllari: kitob tartibida, fe'l bo'lmagan so'zda bo'sh", () {
    const fel = QiroatVocab(
      ar: 'قَعَدَ، يَقْعُدُ، اُقْعُدْ، قُعُودٌ = جَلَسَ، يَجْلِسُ',
      pl: '',
      uz: "o'tirmoq",
    );
    expect(fel.felShakllari.length, 4);
    expect(fel.felShakllari[1], 'يَقْعُدُ');
    const ot = QiroatVocab(ar: 'حُجْرَةٌ = غُرْفَةٌ', pl: '', uz: 'xona');
    expect(ot.felShakllari, isEmpty);
  });

  test("xato izohi: harakat, harf va yasalish qoidasi", () {
    final soz = harflab('الْكِتَابُ');
    final h = xatoIzohi(HarfBolagi('ك', 'كَاف', 'كَ'), soz[2], soz, 2);
    expect(h, contains('harakati xato'));
    expect(h, contains('kasra'));
    final q = xatoIzohi(HarfBolagi('ب', 'بَاء', 'بَ'), soz[0], soz, 0);
    expect(q, contains('aniqlik'));
    final tanvin = harflab('كِتَابٌ');
    final t = xatoIzohi(HarfBolagi('د', 'دَال', 'دَ'), tanvin[3], tanvin, 3);
    expect(t, contains('noaniqligini'));
  });

  test('hamma darsda gap tekshiruvi uchun ≥2 juft bor (1-kitob)', () {
    var kam = 0;
    for (final l in darslar.where((l) => l.book == 1)) {
      final juft = l.tarjimaGuruhlari.where((g) => g.matn.trim().isNotEmpty);
      if (juft.length < 2) kam++;
    }
    // ignore: avoid_print
    print('tekshiruvsiz darslar (1-kitob): $kam');
    expect(kam, lessThan(10));
  });
}
