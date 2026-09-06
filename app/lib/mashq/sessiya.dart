import 'dart:math';

import 'element.dart';

/// Mashq sessiyasining bosqichi.
enum Bosqich {
  /// Faqat shu darsning materiali.
  dars,

  /// Shu darsgacha bo'lgan hamma narsa aralash — zaif joylarga urg'u bilan.
  takror,

  /// Lug'atni o'zbekchadan so'rab, arabchasini harflab yozdirish.
  yozish,

  /// Tugadi.
  tugadi,
}

/// Bitta bosqichning navbati.
///
/// Qoida: element navbatdan CHIQADI faqat to'g'ri javob berilganda. Xato
/// javob bergan element navbat oxiriga qaytadi — ya'ni «bilmasam ham
/// o'tib ketaman» degani yo'q.
///
/// Bosqich «toza» tugagan hisoblanadi, agar birorta ham xato bo'lmasa.
/// Xato bo'lgan bo'lsa — o'sha elementlardan yana bir tur («xatolar
/// ustida») quriladi va u toza o'tguncha davom etadi. Shu bilan
/// foydalanuvchi 100% ga chiqmaguncha oldinga o'tmaydi, lekin bitta xato
/// uchun butun darsni boshidan takrorlashga majbur ham bo'lmaydi —
/// aks holda mashq jazoga aylanib, tashlab ketiladi.
class BosqichNavbati {
  final List<MashqElement> _navbat = [];
  final Set<String> _xatoQilganlar = {};
  final int _boshlangichSoni;

  BosqichNavbati(List<MashqElement> elementlar)
    : _boshlangichSoni = elementlar.length {
    _navbat.addAll(elementlar);
  }

  bool get bosh => _navbat.isEmpty;
  int get qolgan => _navbat.length;
  int get jami => _boshlangichSoni;
  bool get tozaOtdi => _xatoQilganlar.isEmpty;
  List<String> get xatolar => _xatoQilganlar.toList();

  MashqElement? get joriy => _navbat.isEmpty ? null : _navbat.first;

  /// Javob natijasini qayd qiladi va navbatni yangilaydi.
  void javob(bool togri, Random rnd) {
    if (_navbat.isEmpty) return;
    final e = _navbat.removeAt(0);
    if (togri) return;
    _xatoQilganlar.add(e.kalit);
    // Xato element darrov qaytmasin — javob yodda turganda so'rash
    // o'rganish emas, nusxa ko'chirish bo'ladi. 2-4 savol keyin qaytadi.
    final joy = min(_navbat.length, 2 + rnd.nextInt(3));
    _navbat.insert(joy, e);
  }
}

/// Butun mashq sessiyasi: dars → takror.
class MashqSessiya {
  /// Shu darsning elementlari.
  final List<MashqElement> darsniki;

  /// Shu darsgacha bo'lgan (va shu darsning ham) elementlari.
  final List<MashqElement> oldingilar;

  /// Takror bosqichida nechta savol so'ralsin.
  ///
  /// Nega hammasi emas: 100 dars o'tilgach «hamma mavzu» minglab element
  /// bo'ladi va bitta sessiya soatlab cho'ziladi — bu o'rganishni emas,
  /// tashlab ketishni keltiradi. Shuning uchun har safar ZAIF elementlarga
  /// og'ib turadigan tanlanma olinadi: qiynalgan joy tez-tez, mustahkam
  /// joy kamdan-kam qaytadi.
  static const int takrorSoni = 14;

  final Random _rnd;
  final SavolYasagich _yasagich;

  Bosqich bosqich = Bosqich.dars;
  late BosqichNavbati navbat;

  /// Shu sessiyada birinchi urinishda to'g'ri javob berilganlar soni.
  int birinchidanTogri = 0;
  int jamiSoralgan = 0;

  MashqSessiya({required this.darsniki, required this.oldingilar, Random? rnd})
    : _rnd = rnd ?? Random(),
      _yasagich = SavolYasagich(rnd) {
    navbat = BosqichNavbati(_aralash(darsniki));
  }

  List<MashqElement> _aralash(List<MashqElement> x) {
    final r = [...x]..shuffle(_rnd);
    return r;
  }

  /// Zaiflikka qarab tanlanma: og'irligi katta element ko'proq chiqadi.
  List<MashqElement> zaiflarniTanla(List<MashqElement> havza, int soni) {
    if (havza.length <= soni) return _aralash(havza);
    final nusxa = [...havza];
    // Og'irlikka qarab tortish (o'rniga qo'ymasdan): har qadamda umumiy
    // og'irlikdan tasodifiy nuqta tanlanadi.
    final tanlangan = <MashqElement>[];
    while (tanlangan.length < soni && nusxa.isNotEmpty) {
      final jami = nusxa.fold<double>(0, (s, e) => s + e.zaiflik);
      var nuqta = _rnd.nextDouble() * jami;
      var i = 0;
      for (; i < nusxa.length - 1; i++) {
        nuqta -= nusxa[i].zaiflik;
        if (nuqta <= 0) break;
      }
      tanlangan.add(nusxa.removeAt(i));
    }
    return tanlangan;
  }

  /// Joriy savolni yasaydi. Yasab bo'lmasa (chalg'ituvchi yetmasa),
  /// elementni o'tkazib yuboradi.
  MashqSavol? joriySavol() {
    if (bosqich == Bosqich.yozish) {
      final e = navbat.joriy;
      if (e == null) return null;
      return MashqSavol(
        element: e,
        turi: MashqTuri.harflabYoz,
        variantlar: const [],
        togri: 0,
      );
    }
    final havza = bosqich == Bosqich.dars && darsniki.length >= 4
        ? darsniki
        : oldingilar;
    var urinish = 0;
    while (urinish < 4) {
      final e = navbat.joriy;
      if (e == null) return null;
      final s = _yasagich.yasa(e, havza);
      if (s != null) return s;
      // Bu element uchun savol yasab bo'lmadi — navbatdan chiqaramiz.
      navbat.javob(true, _rnd);
      urinish++;
    }
    return null;
  }

  /// Javobni qayd qiladi va kerak bo'lsa keyingi bosqichga o'tadi.
  void javobBer(bool togri, {required bool birinchiUrinish}) {
    jamiSoralgan++;
    if (togri && birinchiUrinish) birinchidanTogri++;
    navbat.javob(togri, _rnd);
    if (!navbat.bosh) return;

    // Tur tugadi. Xato bo'lgan bo'lsa — o'sha elementlar bilan yana bir tur.
    if (!navbat.tozaOtdi) {
      final xatolar = navbat.xatolar.toSet();
      final qayta = (bosqich == Bosqich.dars ? darsniki : oldingilar)
          .where((e) => xatolar.contains(e.kalit))
          .toList();
      navbat = BosqichNavbati(_aralash(qayta));
      return;
    }

    // Toza o'tdi — keyingi bosqich.
    switch (bosqich) {
      case Bosqich.dars:
        final havza = oldingilar.isEmpty ? darsniki : oldingilar;
        final tanlanma = zaiflarniTanla(havza, takrorSoni);
        if (tanlanma.isNotEmpty) {
          bosqich = Bosqich.takror;
          navbat = BosqichNavbati(tanlanma);
          return;
        }
        _yozishgaOt();
      case Bosqich.takror:
        _yozishgaOt();
      case Bosqich.yozish:
      case Bosqich.tugadi:
        bosqich = Bosqich.tugadi;
    }
  }

  /// Yozish bosqichiga o'tish. Yig'ib bo'ladigan so'z bo'lmasa — sessiya
  /// tugaydi (uzun jumlani harflab yozdirish mashq emas, azob bo'lardi).
  void _yozishgaOt() {
    final yoziladigan = darsniki.where(yozibBoladi).toList();
    if (yoziladigan.isEmpty) {
      bosqich = Bosqich.tugadi;
      return;
    }
    bosqich = Bosqich.yozish;
    navbat = BosqichNavbati(_aralash(yoziladigan));
  }

  /// So'zni harflab yig'ish mumkinmi: 2-8 ta asosiy harf va bitta so'z.
  static bool yozibBoladi(MashqElement e) {
    if (e.ar.trim().contains(' ')) return false;
    final n = harflarga(e.ar).length;
    return n >= 2 && n <= 8;
  }

  /// Sessiya bo'yicha aniqlik (0..100).
  int get foiz =>
      jamiSoralgan == 0 ? 0 : (birinchidanTogri * 100 / jamiSoralgan).round();
}
