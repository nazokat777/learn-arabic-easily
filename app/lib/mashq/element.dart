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

  const MashqElement({
    required this.kalit,
    required this.ar,
    required this.uz,
    required this.darsId,
    required this.tartib,
    required this.modul,
    String? ovoz,
  }) : ovoz = ovoz ?? ar;

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
      turi == MashqTuri.arabchaTop || turi == MashqTuri.tinglabTop;
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
    ];
    return turlar[_rnd.nextInt(turlar.length)];
  }

  /// Bitta savol yasaydi. Chalg'ituvchilar [havza] dan olinadi.
  ///
  /// Yetarli chalg'ituvchi bo'lmasa (havzada 4 tadan kam har xil javob),
  /// `null` qaytadi — bunday savolni ko'rsatishdan ko'ra o'tkazib yuborish
  /// yaxshiroq, aks holda variantlar takrorlanib, «to'g'ri javob ikkita»
  /// bo'lib qolardi.
  MashqSavol? yasa(MashqElement e, List<MashqElement> havza, {MashqTuri? tur}) {
    final turi = tur ?? turTanla(e);

    if (turi == MashqTuri.tugriMi) {
      // Yarmi to'g'ri, yarmi soxta juftlik.
      final togri = _rnd.nextBool();
      var korsatiladigan = e.uz;
      if (!togri) {
        final boshqa = havza.where((x) => x.uz.trim() != e.uz.trim()).toList();
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
    for (final x in havza) {
      final j = javob(x);
      if (j.trim().isEmpty || j == togriJavob) continue;
      boshqalar.add(j);
    }
    if (boshqalar.length < 3) return null;

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
