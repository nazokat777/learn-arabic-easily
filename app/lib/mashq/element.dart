import 'dart:math';

import '../main.dart';

/// Mashq qilinadigan bitta FAKT: arabcha tomon ↔ o'zbekcha tomon.
///
/// Butun ilova uchun yagona model: harf–nomi, harakat–tovushi, so'z–ma'nosi,
/// qoida–tarjimasi, sarf misoli–izohi — hammasi shu ko'rinishga tushadi.
/// Shu sababli mashq mexanizmi (savol yasash, zaiflikni aniqlash,
/// takrorlash) bir marta yozilib, hamma modulga ishlaydi.
class MashqElement {
  /// Taraqqiyot kaliti — daraja va xatolar shu bo'yicha saqlanadi.
  /// Ko'rinishi: `modul::darsId::arabcha`.
  final String kalit;

  /// Arabcha tomon (harf, so'z, jumla).
  final String ar;

  /// O'zbekcha tomon (nomi, ma'nosi, tarjimasi).
  final String uz;

  /// Qaysi darsdan — takrorlash tartibi shu bo'yicha quriladi.
  final String darsId;

  /// Dars raqami (kichikdan kattaga) — «shu darsgacha hammasi» uchun.
  final int tartib;

  /// Modul nomi — natijani ko'rsatishda ishlatiladi («Nahv», «Qiroat»...).
  final String modul;

  /// Ovoz uchun matn. Odatda [ar], lekin uzun jumlada qisqasi berilishi
  /// mumkin. Bo'sh bo'lsa — ovoz tugmasi ko'rsatilmaydi.
  final String ovoz;

  /// Tasnif elementi: `uz` — ma'no emas, TUR nomi (masalan «Noqis»).
  /// Savol matni boshqacha («qaysi turga kiradi?»), yozish bosqichiga
  /// kirmaydi. Manba — kitobning o'z jadvali (katak ↔ ustun).
  final bool turkum;

  /// Tasnif guruhi (masalan «sarf-3»): chalg'ituvchilar faqat shu guruh
  /// ichidan — boshqa darsning so'zi ham o'sha turga kirishi mumkin va
  /// ikkinchi to'g'ri javob bo'lib qolardi.
  final String guruh;

  /// Kitobdagi ta'rif (tasnif uchun): javobdan keyin «Mozi — o'tgan
  /// zamonda … dalolat qiladigan fe'l» ko'rsatiladi. Bo'sh bo'lishi mumkin.
  final String izoh;

  /// Ko'pligi (kitobda berilgan bo'lsa; «=» / «،» bilan bir nechta shakl).
  /// So'z ko'rsatilgan har joyda birlik bilan birga chiqadi — kitob
  /// lug'ati ikkalasini birga beradi.
  final String pl;

  const MashqElement({
    required this.kalit,
    required this.ar,
    required this.uz,
    required this.darsId,
    required this.tartib,
    required this.modul,
    String? ovoz,
    this.turkum = false,
    this.guruh = '',
    this.izoh = '',
    this.pl = '',
  }) : ovoz = ovoz ?? ar;

  /// Ko'plikning o'qiladigan shakllari (qo'shimchagina bo'lsa — yo'q).
  List<String> get plShakllari => pl
      .split(RegExp(r'\s*[=،,]\s*'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && !s.startsWith('ـ'))
      .toList();

  /// Element hozir qanchalik zaif (katta son = ko'proq mashq kerak).
  double get zaiflik => progress.zaiflik(kalit);

  /// To'liq o'zlashtirilganmi (xatosiz, yetarli marta takrorlangan).
  bool get yodlangan => progress.isWordLearned(kalit);
}

/// So'zni harakatlarsiz asosiy harflarga ajratadi.
///
/// Harflab yig'ishda harakatlar tashlanadi: «كِتَاب» ni harakati bilan
/// yig'dirish o'rganishga hech narsa qo'shmaydi, faqat chalkashtiradi —
/// maqsad harflar ketma-ketligini eslash.
List<String> harflarga(String ar) => ar
    .replaceAll(RegExp('[ً-ْٰـ]'), '')
    .split('')
    .where((c) => c.trim().isNotEmpty)
    .toList();

/// Savol turlari — har biri xotiraning boshqa yo'lini ishlatadi.
///
/// Nega bittasi yetmaydi: faqat «arabcha → ma'nosi» so'ralsa, o'quvchi
/// so'zni TANIYDIGAN bo'ladi, lekin o'zi ESLAY olmaydi. Teskari savol
/// (ma'nosi → arabcha) eslashni, tinglash esa tovush bilan bog'lashni
/// mashq qildiradi. Uchalasi birga bo'lgandagina so'z haqiqatan yodlanadi.
enum MashqTuri {
  /// Arabcha ko'rsatiladi → ma'nosi tanlanadi (tanish).
  manoTop,

  /// Ma'nosi ko'rsatiladi → arabchasi tanlanadi (eslash — qiyinroq).
  arabchaTop,

  /// Faqat ovoz eshittiriladi → arabchasi tanlanadi (quloq).
  tinglabTop,

  /// «Bu juftlik to'g'rimi?» — tez va oson, ishonch beradi.
  tugriMi,

  /// O'zbekchasi ko'rsatiladi → arabchasini HARFLAB yig'adi.
  ///
  /// Eng kuchli usul: tanish emas, ISHLAB CHIQARISH. Variantdan tanlashda
  /// javob ko'z oldida turadi va xotira zo'riqmaydi; harflab yig'ishda esa
  /// so'zni o'zi qaytadan tuzadi — shundagina u faol xotiraga o'tadi.
  harflabYoz,

  /// Birlik ko'rsatiladi → KO'PLIGI tanlanadi (kitob lug'ati juftligi).
  ///
  /// Ko'plikni faqat ko'rsatib qo'yish yodlatmaydi — so'ralsagina xotiraga
  /// o'tadi. Chalg'ituvchilar — boshqa so'zlarning ko'pliklari.
  koplikTop,
}

/// Bitta so'raladigan savol: element + qaysi turda so'ralishi.
class MashqSavol {
  final MashqElement element;
  final MashqTuri turi;

  /// Variantlar (to'g'risi ham shu ro'yxatda).
  final List<String> variantlar;

  /// To'g'ri variant indeksi.
  final int togri;

  /// «tugriMi» turida ko'rsatiladigan juftlik to'g'rimi.
  final bool juftlikTogri;

  const MashqSavol({
    required this.element,
    required this.turi,
    required this.variantlar,
    required this.togri,
    this.juftlikTogri = true,
  });

  /// Variantlar arabchami (chizishda o'ngdan chapga va Amiri kerak).
  bool get arabchaVariantlar =>
      turi == MashqTuri.arabchaTop ||
      turi == MashqTuri.tinglabTop ||
      turi == MashqTuri.koplikTop;
}

/// Elementlardan savol yasaydi.
///
/// Chalg'ituvchi variantlar AYNAN SHU to'plamdan olinadi — begona so'z
/// chalg'ituvchi bo'lsa, savol osonlashib ketadi va mashq ma'nosini
/// yo'qotadi.
class SavolYasagich {
  final Random _rnd;
  SavolYasagich([Random? rnd]) : _rnd = rnd ?? Random();

  /// Turlarni elementning darajasiga qarab tanlaydi: yangi element oson
  /// turdan boshlanadi, o'zlashtirilgani qiyinroq turda so'raladi.
  MashqTuri turTanla(MashqElement e, {bool ovozBor = true}) {
    final daraja = progress.wordMastery(e.kalit);
    final turlar = <MashqTuri>[
      MashqTuri.manoTop,
      if (daraja >= 1) MashqTuri.arabchaTop,
      if (daraja >= 2 && ovozBor && e.ovoz.isNotEmpty) MashqTuri.tinglabTop,
      if (daraja >= 1) MashqTuri.tugriMi,
      // Ko'pligi bor so'zda ko'plik savoli ikki marta kiradi — u kamdan-kam
      // emas, muntazam so'ralsin.
      if (e.pl.isNotEmpty) MashqTuri.koplikTop,
      if (e.pl.isNotEmpty && daraja >= 1) MashqTuri.koplikTop,
    ];
    return turlar[_rnd.nextInt(turlar.length)];
  }

  /// Ko'plik savoli: to'g'ri javob — elementning birinchi ko'plik shakli,
  /// chalg'ituvchilar — havzadagi boshqa so'zlarning ko'pliklari.
  MashqSavol? _koplik(MashqElement e, List<MashqElement> havza) {
    final shakllar = e.plShakllari;
    if (shakllar.isEmpty) return null;
    final togriJavob = shakllar.first;
    final boshqalar = <String>{};
    for (final x in havza) {
      if (x.pl.isEmpty || x.uz.trim() == e.uz.trim()) continue;
      for (final sh in x.plShakllari) {
        if (sh != togriJavob && !shakllar.contains(sh)) boshqalar.add(sh);
      }
    }
    // Ko'plik kam bo'lgan darsda boshqa so'zlarning BIRLIGI ham chalg'ituvchi
    // bo'la oladi (ko'rinishi ko'plikka o'xshamaydi — lekin variant yetadi).
    if (boshqalar.length < 3) {
      for (final x in havza) {
        if (x.uz.trim() != e.uz.trim() && x.ar != e.ar) boshqalar.add(x.ar);
        if (boshqalar.length >= 6) break;
      }
    }
    if (boshqalar.length < 3) return null;
    final ro = boshqalar.toList()..shuffle(_rnd);
    final variantlar = <String>[togriJavob, ...ro.take(3)]..shuffle(_rnd);
    return MashqSavol(
      element: e,
      turi: MashqTuri.koplikTop,
      variantlar: variantlar,
      togri: variantlar.indexOf(togriJavob),
    );
  }

  /// Bitta savol yasaydi. Chalg'ituvchilar [havza] dan olinadi.
  ///
  /// Yetarli chalg'ituvchi bo'lmasa (havzada 4 tadan kam har xil javob),
  /// `null` qaytadi — bunday savolni ko'rsatishdan ko'ra o'tkazib yuborish
  /// yaxshiroq, aks holda variantlar takrorlanib, «to'g'ri javob ikkita»
  /// bo'lib qolardi.
  MashqSavol? yasa(MashqElement e, List<MashqElement> havza, {MashqTuri? tur}) {
    final turi = tur ?? turTanla(e);

    if (turi == MashqTuri.koplikTop) return _koplik(e, havza);

    if (turi == MashqTuri.tugriMi) {
      // Yarmi to'g'ri, yarmi soxta juftlik.
      final togri = _rnd.nextBool();
      var korsatiladigan = e.uz;
      if (!togri) {
        final boshqa = havza
            .where(
              (x) =>
                  x.uz.trim() != e.uz.trim() &&
                  x.turkum == e.turkum &&
                  (!e.turkum || x.guruh == e.guruh),
            )
            .toList();
        if (boshqa.isEmpty) return null;
        korsatiladigan = boshqa[_rnd.nextInt(boshqa.length)].uz;
      }
      return MashqSavol(
        element: e,
        turi: turi,
        variantlar: [korsatiladigan],
        togri: togri ? 0 : -1,
        juftlikTogri: togri,
      );
    }

    final arabchaJavob = turi != MashqTuri.manoTop;
    String javob(MashqElement x) => arabchaJavob ? x.ar : x.uz;

    final togriJavob = javob(e);
    final boshqalar = <String>{};
    // Tasnif savoli — chalg'ituvchilar faqat o'z guruhidan; oddiy savolga
    // tasnif elementi (tur nomi) chalg'ituvchi bo'lmaydi.
    final manba = e.turkum
        ? havza.where((x) => x.turkum && x.guruh == e.guruh)
        : havza.where((x) => !x.turkum);
    for (final x in manba) {
      final j = javob(x);
      if (j.trim().isEmpty || j == togriJavob) continue;
      // Teskari savolda («qaysi kalima noqis?») bir xil ma'noli boshqa
      // element ham to'g'ri javob bo'lardi — ikki to'g'ri variant
      // bo'lmasin. Tasnifda bu har doim, oddiy so'zlarda sinonimlarda.
      if (arabchaJavob && x.uz.trim() == e.uz.trim()) continue;
      boshqalar.add(j);
    }
    // Tasnifda «qaysi tur?» savoli 2–3 turli guruhda ham ma'noli
    // (Muzakkar / Muannas) — kamida bitta chalg'ituvchi yetadi; oddiy
    // so'zlarda 4 variant.
    if (boshqalar.length < (e.turkum ? 1 : 3)) return null;

    final ro = boshqalar.toList()..shuffle(_rnd);
    final variantlar = <String>[togriJavob, ...ro.take(3)]..shuffle(_rnd);
    return MashqSavol(
      element: e,
      turi: turi,
      variantlar: variantlar,
      togri: variantlar.indexOf(togriJavob),
    );
  }
}
