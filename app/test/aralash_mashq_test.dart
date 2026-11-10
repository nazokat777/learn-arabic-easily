// Aralash mashq: hamma darsda savollar to'g'ri yasaladi, ko'pligi bor so'z
// uch tomondan so'raladi, ekran javob berib oxirigacha yuradi.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' show progress, repo;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/aralash_mashq.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  progress = Progress();
  final darslar =
      ((json.decode(
                    File(
                      'assets/content/qiroat_lessons.json',
                    ).readAsStringSync(),
                  )
                  as Map)['lessons']
              as List)
          .map((e) => QiroatLesson.fromJson(e as Map<String, dynamic>))
          .toList();
  repo = ContentRepository()..qiroatLessons = darslar;
  setUpAll(() => progress.load());

  test("hamma darsda savollar to'g'ri, ko'plik uch tomondan", () {
    final turlar = <AralashTur, int>{};
    for (final l in darslar) {
      final ro = AralashYasagich(l, rnd: Random(1)).yasa();
      for (final s in ro) {
        turlar[s.tur] = (turlar[s.tur] ?? 0) + 1;
        if (s.variantlar.isNotEmpty) {
          expect(s.variantlar.length, 4);
          expect(s.variantlar.toSet().length, 4);
          expect(s.variantlar, contains(s.togri));
        }
        if (s.tartib.isNotEmpty) {
          expect(s.bolaklar.length, greaterThanOrEqualTo(s.tartib.length));
        }
        if (s.tur == AralashTur.koplik) {
          expect(s.togri, s.v!.plShakllari.first);
          // Chalg'ituvchi o'sha so'zning boshqa ko'plik shakli emas.
          for (final o in s.variantlar) {
            if (o != s.togri) expect(s.v!.plShakllari, isNot(contains(o)));
          }
        }
      }
      for (final v in AralashYasagich(l).darsSozlari) {
        if (v.plShakllari.isEmpty) continue;
        final w = ro.where((s) => s.v?.ar == v.ar);
        expect(
          w.any((s) => s.tur == AralashTur.koplik),
          isTrue,
          reason: '${l.book}-${l.num} ${v.uz}',
        );
        expect(w.any((s) => s.tur == AralashTur.birlikTop), isTrue);
      }
    }
    // ignore: avoid_print
    print(turlar);
    for (final t in AralashTur.values) {
      expect(turlar[t] ?? 0, greaterThan(0), reason: '$t');
    }
  });

  testWidgets("ekran: to'g'ri javoblar bilan oxirigacha yuradi", (t) async {
    t.view.physicalSize = const Size(900, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final l = darslar[5];
    await t.pumpWidget(MaterialApp(home: AralashMashqEkrani(lesson: l)));
    final st = t.state(find.byType(AralashMashqEkrani)) as dynamic;
    for (var k = 0; k < 400; k++) {
      if (find.byKey(const ValueKey('qayta')).evaluate().isNotEmpty) break;
      final AralashSavol s = st.joriy;
      if (s.tur == AralashTur.juftlash) {
        for (final v in s.juftlar) {
          await t.tap(find.byKey(ValueKey('juft-ar-${v.ar}')));
          await t.pump();
          await t.tap(find.byKey(ValueKey('juft-uz-${v.ar}')));
          await t.pump();
        }
      } else if (s.tur == AralashTur.yozma) {
        for (final ch in s.togri.split('')) {
          final f = find.byKey(ValueKey('harf-$ch'));
          if (f.evaluate().isEmpty) continue; // harakatsiz ham qabul
          await t.tap(f);
          await t.pump();
        }
        await t.tap(find.byKey(const ValueKey('yozma-tekshir')));
        await t.pump();
      } else if (s.tur == AralashTur.tezkor) {
        await t.tap(
          find.byKey(ValueKey(s.togri == 'ha' ? 'tez-ha' : 'tez-yoq')),
        );
        await t.pump();
      } else if (s.tartib.isNotEmpty) {
        final ishlatilgan = <int>{};
        for (final b in s.tartib) {
          final i = [
            for (var j = 0; j < s.bolaklar.length; j++) j,
          ].firstWhere((j) => s.bolaklar[j] == b && !ishlatilgan.contains(j));
          ishlatilgan.add(i);
          await t.tap(find.byKey(ValueKey('bolak-$i')));
          await t.pump();
        }
      } else {
        await t.tap(find.byKey(ValueKey('variant-${s.togri}')));
        await t.pump();
      }
      await t.pump(const Duration(seconds: 1));
    }
    expect(find.byKey(const ValueKey('qayta')), findsOneWidget);
    expect(find.text('100% birinchi urinishda'), findsOneWidget);
  });
}
