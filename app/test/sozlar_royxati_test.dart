import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/content.dart';
import 'package:learn_arabic/main.dart' as m;
import 'package:learn_arabic/mashq/sozlar_royxati.dart';
import 'package:learn_arabic/progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yodlashdan oldingi to'liq ro'yxat va oxiridagi yaxshi/yomon ro'yxatlari.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  m.progress = Progress();
  final dars = QiroatLesson.fromJson(
    (json.decode(File('assets/content/qiroat_lessons.json').readAsStringSync())['lessons']
            as List)
        .first as Map<String, dynamic>,
  );

  testWidgets("oldindan ro'yxat: hamma so'z tarjima va o'qilishi bilan", (
    tester,
  ) async {
    var boshlandi = false;
    final sozlar = darsSozlari(dars);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SozlarOldindanRoyxat(
            sozlar: sozlar,
            onBoshla: () => boshlandi = true,
          ),
        ),
      ),
    );
    expect(find.textContaining("Avval so'zlar ro'yxati: ${sozlar.length} ta"),
        findsOneWidget);
    // Birinchi so'zning tarjimasi va o'qilishi ko'rinadi.
    expect(find.textContaining('kitob'), findsWidgets);
    expect(talaffuzOf(sozlar.first), isNotEmpty);
    await tester.tap(find.text('Yodlashni boshlash'));
    expect(boshlandi, true);
  });

  testWidgets("natija: hamma so'z ikki ro'yxatdan BIRIDA, qisqartirilmaydi", (
    tester,
  ) async {
    final sozlar = darsSozlari(dars);
    // Yarmi xato qilingan, yarmi toza — hammasi (kamida) bitta ro'yxatga tushadi.
    final xato = {for (final e in sozlar.take(sozlar.length ~/ 2)) e.kalit};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SozlarNatijaRoyxati(sozlar: sozlar, xatolar: xato),
          ),
        ),
      ),
    );
    expect(find.textContaining('Yaxshi yodlanmadi'), findsOneWidget);
    // Sarlavhalardagi sonlar yig'indisi = so'zlar soni.
    final raqamlar = RegExp(r'\((\d+)\)');
    var jami = 0;
    for (final w in tester.widgetList<Text>(find.byType(Text))) {
      final t = w.data ?? '';
      if (t.startsWith('Yaxshi yodlan')) {
        jami += int.parse(raqamlar.firstMatch(t)!.group(1)!);
      }
    }
    expect(jami, sozlar.length);
  });
}
