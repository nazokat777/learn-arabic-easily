import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/main.dart' as app;
import 'package:learn_arabic/progress.dart';
import 'package:learn_arabic/screens/hafta_hisoboti.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hafta hisoboti: o'tgan haftada faollik bo'lsa bir marta ko'rsatiladi,
/// ko'rilgach shu hafta qayta chiqmaydi; raqamlar tarixdan to'g'ri yig'iladi.
void main() {
  String sana(DateTime n) =>
      '${n.year}-${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';

  DateTime buDushanba() {
    final b = DateTime.now();
    return DateTime(b.year, b.month, b.day - (b.weekday - 1));
  }

  test("o'tgan hafta bo'sh — hisobot kerak emas", () async {
    SharedPreferences.setMockInitialValues({});
    final p = Progress();
    await p.load();
    expect(p.haftaHisobotiKerak, isFalse);
  });

  test("o'tgan hafta faol — bir marta kerak, ko'rilgach yo'q", () async {
    final d = buDushanba();
    final tarix = {
      sana(d.subtract(const Duration(days: 7))): [10, 8, 20], // o'tgan Du
      sana(d.subtract(const Duration(days: 5))): [30, 27, 45], // o'tgan Ch
      sana(d.subtract(const Duration(days: 10))): [5, 5, 9], // undan oldingi
    };
    SharedPreferences.setMockInitialValues({'kunTarix': json.encode(tarix)});
    final p = Progress();
    await p.load();
    expect(p.haftaHisobotiKerak, isTrue);
    expect(p.otganHaftaNatijasi(), (40, 35, 65, 0));
    expect(p.undanOldingiHaftaNatijasi(), (5, 5, 9));
    final kunlar = p.otganHaftaKunlari();
    expect(kunlar.length, 7);
    expect(kunlar.first.$1.weekday, DateTime.monday);
    expect(kunlar.first.$2, 10);
    expect(kunlar[2].$2, 30);

    await p.haftaHisobotiniKordim();
    expect(p.haftaHisobotiKerak, isFalse);
    // Saqlangan: qayta yuklaganda ham ko'rilgan.
    final p2 = Progress();
    await p2.load();
    expect(p2.haftaHisobotiKurildi, isTrue);
  });

  testWidgets('oyna: ustunlar, eng yaxshi kun, o\'sish', (tester) async {
    final d = buDushanba();
    SharedPreferences.setMockInitialValues({
      'kunTarix': json.encode({
        sana(d.subtract(const Duration(days: 7))): [10, 8, 20],
        sana(d.subtract(const Duration(days: 5))): [30, 27, 45],
        sana(d.subtract(const Duration(days: 10))): [5, 5, 9],
      }),
    });
    app.progress = Progress();
    await app.progress.load();
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold();
          },
        ),
      ),
    );
    final f = haftaHisobotiOynasi(ctx);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('O\'tgan hafta hisoboti'), findsOneWidget);
    expect(find.textContaining('Eng yaxshi kun: chorshanba'), findsOneWidget);
    expect(find.textContaining('+56 ball'), findsOneWidget); // 65 - 9
    expect(find.text('savol'), findsOneWidget);
    await tester.tap(find.text('Yangi haftani boshlaymiz'));
    await tester.pumpAndSettle();
    await f;
    expect(app.progress.haftaHisobotiKerak, isFalse);
  });
}
