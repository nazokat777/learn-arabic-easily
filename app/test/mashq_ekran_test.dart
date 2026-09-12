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
// 260 ms kutish lahzasi + 1500 ms xato ko'rsatish + o'tish animatsiyasi —
// ikkita savol bir vaqtda daraxtda turmasin.
Future<void> _kut(WidgetTester tester, [int ms = 2800]) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(Duration(milliseconds: ms ~/ 8));
  }
}

/// Joriy savolga javob beradi. Savol turini ko'rsatma matnidan aniqlaydi —
/// foydalanuvchi ham ekrandan aynan shuni o'qiydi.
Future<void> _javobBer(WidgetTester tester, {bool togri = true}) async {
  // Daraja oynasi — butun ekranli; o'quvchi o'zi yopadi.
  if (_bor('Davom etamiz!')) {
    await tester.tap(find.text('Davom etamiz!'));
    await _kut(tester);
    return;
  }
  // Raund bekati — «davom» bosiladi; qiyin so'z kartasi — «eslab oldim».
  if (_bor('Bugunga yetadi')) {
    await tester.tap(find.textContaining('Davom etish'));
    await _kut(tester);
    return;
  }
  if (_bor('Eslab oldim')) {
    await tester.tap(find.text('Eslab oldim'));
    await _kut(tester);
    return;
  }
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
    final ar = _korinayotgan(_arlar);
    if (ar == null) {
      // O'tish animatsiyasi yoki daraja banneri — bir oz kutib qaytamiz.
      await _kut(tester);
      return;
    }
    final javob = _arBoyicha(ar).uz;
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

  testWidgets("har 8 savoldan keyin bekat chiqadi, yulduzlar ko'rinadi", (
    tester,
  ) async {
    await _ochish(tester, 'sinov-3');
    var bekatKorildi = false;
    var qadam = 0;
    while (!_tugadi() && qadam < 150) {
      if (_bor('Bugunga yetadi')) {
        bekatKorildi = true;
        expect(find.textContaining('-raund'), findsWidgets);
        expect(find.byIcon(Icons.star_rounded), findsWidgets);
      }
      await _javobBer(tester);
      qadam++;
    }
    expect(bekatKorildi, isTrue, reason: 'raund bekati chiqishi shart');
  });

  testWidgets("«bugunga yetadi» o'zlashtirish belgisini bermaydi", (
    tester,
  ) async {
    await _ochish(tester, 'sinov-4');
    var qadam = 0;
    while (!_bor('Bugunga yetadi') && qadam < 40) {
      await _javobBer(tester);
      qadam++;
    }
    expect(find.text('Bugunga yetadi'), findsOneWidget);
    // Bekat tugmalari kechikib (Reveal) chiqadi — animatsiya tugasin.
    await _kut(tester);
    await tester.tap(find.text('Bugunga yetadi'));
    await _kut(tester);
    expect(find.text('Yaxshi dam oling'), findsOneWidget);
    expect(progress.isMastered('sinov-4'), isFalse);
  });

  testWidgets("3 marta adashilgan so'z avval o'rgatiladi, keyin so'raladi", (
    tester,
  ) async {
    // «ketdi» so'zini oldindan uch marta xato qilingan deb belgilaymiz.
    final kalit = _el('ذَهَبَ', 'ketdi').kalit;
    for (var i = 0; i < 3; i++) {
      await progress.bumpWord(kalit, false);
    }
    expect(progress.qiyinMi(kalit), isTrue);

    await _ochish(tester, 'sinov-5');
    var kartaKorildi = false;
    var bosqichKorildi = false;
    var qadam = 0;
    while (!_tugadi() && qadam < 200) {
      if (_bor('Eslab oldim')) {
        kartaKorildi = true;
        expect(find.text('ketdi'), findsWidgets);
      }
      if (_bor("Qiyin so'zlar ustida")) bosqichKorildi = true;
      await _javobBer(tester);
      qadam++;
    }
    expect(kartaKorildi, isTrue, reason: "o'rgatish kartasi chiqishi shart");
    expect(bosqichKorildi, isTrue, reason: 'qiyin bosqichi chiqishi shart');
    // Ketma-ket uch marta to'g'ri bo'lgach, «qiyin» belgisi olinadi.
    expect(progress.ketmaKetTogri(kalit), greaterThanOrEqualTo(3));
    expect(progress.qiyinMi(kalit), isFalse);
  });
}
