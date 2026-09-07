// Mashq ekranining uchidan-uchiga tekshiruvi: uch bosqich ham chindan
// ochiladimi, harflab yozish ishlaydimi va yakunda hisobot chiqadimi.
//
// Nega kerak: sessiya mantig'i alohida tekshirilgan, ammo ekran o'sha
// mantiqni to'g'ri chizishi va tugmalar to'g'ri javobni uzatishi
// tekshirilmagan edi. Aynan shu joyda xato bo'lsa, o'quvchi
// «o'zlashtirdim» degan xulosani asossiz olardi.
//
// Ovoz berilmaydi (`ovoz: ''`) — shunda «tinglab top» turi chiqmaydi va
// test TTS plaginisiz ishlaydi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/main.dart' show progress;
import 'package:learn_arabic/mashq/element.dart';
import 'package:learn_arabic/mashq/mashq_ekran.dart';
import 'package:learn_arabic/progress.dart';

MashqElement _el(String ar, String uz) => MashqElement(
  kalit: 'sinov::$ar',
  ar: ar,
  uz: uz,
  darsId: 'sinov-1',
  tartib: 1,
  modul: 'Sinov',
  ovoz: '',
);

/// Harflari takrorlanmaydigan qisqa so'zlar — harflab yozishda qaysi
/// tugma bosilgani aniq bo'lsin.
final _elementlar = [
  _el('كَتَبَ', 'yozdi'),
  _el('ذَهَبَ', 'ketdi'),
  _el('سَمِعَ', 'eshitdi'),
  _el('فَتَحَ', 'ochdi'),
  _el('نَصَرَ', 'yordam berdi'),
];

MashqElement _arBoyicha(String ar) => _elementlar.firstWhere((e) => e.ar == ar);
MashqElement _uzBoyicha(String uz) => _elementlar.firstWhere((e) => e.uz == uz);

Iterable<String> get _arlar => _elementlar.map((e) => e.ar);
Iterable<String> get _uzlar => _elementlar.map((e) => e.uz);

bool _bor(String matn) => find.text(matn).evaluate().isNotEmpty;

/// Ekranda ko'rinib turgan matnlardan birinchisini qaytaradi.
String? _korinayotgan(Iterable<String> nomzodlar) {
  for (final n in nomzodlar) {
    if (_bor(n)) return n;
  }
  return null;
}

/// Animatsiyalar tugashini kutadi. `pumpAndSettle` ishlatilmaydi: ekranda
/// to'xtovsiz aylanadigan bezaklar bor va u hech qachon tinchimaydi.
Future<void> _kut(WidgetTester tester, [int ms = 2200]) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(Duration(milliseconds: ms ~/ 8));
  }
}

/// Joriy savolga javob beradi. Savol turini ko'rsatma matnidan aniqlaydi —
/// foydalanuvchi ham ekrandan aynan shuni o'qiydi.
Future<void> _javobBer(WidgetTester tester, {bool togri = true}) async {
  if (_bor('Arabchasini harflab yozing')) {
    final harflar = harflarga(_uzBoyicha(_korinayotgan(_uzlar)!).ar);
    // Xato yig'ish uchun teskari tartib: sinov so'zlarida takrorlanuvchi
    // harf yo'q, shuning uchun teskarisi albatta noto'g'ri chiqadi.
    final tartib = togri ? harflar : harflar.reversed.toList();
    for (final harf in tartib) {
      await tester.tap(find.text(harf).last);
      await tester.pump();
    }
  } else if (_bor("Bu juftlik to'g'rimi?")) {
    final ar = _korinayotgan(_arlar)!;
    final korsatilgan = _korinayotgan(_uzlar)!;
    final juftlikTogri = _arBoyicha(ar).uz == korsatilgan;
    await tester.tap(find.text(juftlikTogri == togri ? "To'g'ri" : 'Xato'));
  } else if (_bor('Buning arabchasi qaysi?')) {
    final javob = _uzBoyicha(_korinayotgan(_uzlar)!).ar;
    final bosiladi = togri
        ? javob
        : _arlar.firstWhere((a) => a != javob && _bor(a));
    await tester.tap(find.text(bosiladi).last);
  } else {
    final javob = _arBoyicha(_korinayotgan(_arlar)!).uz;
    final bosiladi = togri
        ? javob
        : _uzlar.firstWhere((u) => u != javob && _bor(u));
    await tester.tap(find.text(bosiladi).last);
  }
  await _kut(tester);
}

/// Sessiya tugadimi: mukammal o'tilsa sarlavha boshqacha bo'ladi.
bool _tugadi() => _bor('Mukammal!') || _bor('Mashq tugadi');

Future<void> _ochish(WidgetTester tester, String darsId) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MashqEkran(
        sarlavha: 'Sinov mashqi',
        darsniki: _elementlar,
        oldingilar: _elementlar,
        darsId: darsId,
      ),
    ),
  );
  await _kut(tester);
}

void main() {
  // `progress` — main.dart dagi `late final` global; bir marta beriladi.
  progress = Progress();

  testWidgets("uch bosqich ham o'tiladi va yakunda hisobot chiqadi", (
    tester,
  ) async {
    await _ochish(tester, 'sinov-1');
    expect(find.text('Shu darsning materiali'), findsOneWidget);

    final korilgan = <String>{};
    var qadam = 0;
    while (!_tugadi() && qadam < 150) {
      for (final nom in const [
        'Shu darsning materiali',
        'Aralash takror — oldingi darslar ham',
        "Harflab yozish — o'zbekchadan arabchaga",
      ]) {
        if (_bor(nom)) korilgan.add(nom);
      }
      await _javobBer(tester);
      qadam++;
    }

    expect(
      korilgan.length,
      3,
      reason: "dars, aralash takror va harflab yozish — uchalasi ham bo'lsin",
    );
    expect(find.text('Mukammal!'), findsOneWidget);
    expect(find.textContaining('100%'), findsWidgets);
    expect(progress.isMastered('sinov-1'), isTrue);
  });

  testWidgets('xato javobdan keyin sessiya mukammal hisoblanmaydi', (
    tester,
  ) async {
    await _ochish(tester, 'sinov-2');

    await _javobBer(tester, togri: false);

    var qadam = 0;
    while (!_tugadi() && qadam < 200) {
      await _javobBer(tester);
      qadam++;
    }

    expect(find.text('Mashq tugadi'), findsOneWidget);
    expect(progress.isMastered('sinov-2'), isFalse);
    // Qiynalgan element yakuniy hisobotda ko'rsatiladi.
    expect(find.textContaining('qiyin'), findsWidgets);
  });
}
