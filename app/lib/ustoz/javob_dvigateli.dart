import '../arabic.dart';
import '../harflab.dart';
import 'bilim_bazasi.dart';

/// Ustozning bitta javobi.
class Javob {
  /// Asosiy javob (o'zbekcha izoh).
  final String matn;

  /// Arabcha natija (tarjima yoki topilgan jumla) — bo'lsa, katta va
  /// o'qiladigan qilib chiziladi.
  final String arabcha;

  /// So'zma-so'z tahlil (arabcha so'z → ma'nosi/izohi).
  final List<({String ar, String uz})> tahlil;

  /// Kitobdan olingan parchalar (manbasi bilan) — javob shulardan.
  final List<Parcha> manbalar;

  /// Ishonch: aniq (kitobda aynan bor) yoki taxminiy (so'zma-so'z yig'ilgan).
  final bool aniq;
  const Javob({
    required this.matn,
    this.arabcha = '',
    this.tahlil = const [],
    this.manbalar = const [],
    this.aniq = false,
  });
}

/// Savol turi.
enum SavolTuri { arabchaMatn, ozbekchaMatn, qoidaSavoli }

/// KITOBDAN JAVOB BERUVCHI DVIGATEL (serversiz, offline).
///
/// Uch xil so'rovni farqlaydi:
///  1. Arabcha matn — o'zbekchaga o'giradi (kitobda aynan bo'lsa — kitob
///     tarjimasi; bo'lmasa so'zma-so'z, har so'z ma'nosi bilan).
///  2. O'zbekcha jumla — arabchasini beradi (kitobda bor jumla topilsa
///     aynan; bo'lmasa so'zma-so'z, «taxminiy» belgisi bilan).
///  3. Qoida savoli («majhul nima», «jazm qachon») — Sharh/Nahv/Sarf
///     matnidan tegishli qoidani manbasi bilan keltiradi.
///
/// Nega o'ylab topmaydi: ilova kitobga sodiq. Javob kitobda bo'lmasa,
/// «kitobda topilmadi» deyiladi — noto'g'ri qoida o'rgatishdan ko'ra shu
/// yaxshiroq.
class JavobDvigateli {
  JavobDvigateli._();
  static final JavobDvigateli instance = JavobDvigateli._();

  final _baza = BilimBazasi.instance;

  static final _arabRe = RegExp(r'[ء-ي]');

  /// So'roq so'zlari — matn tarjima emas, SAVOL ekanini bildiradi.
  static const _savolSozlari = [
    'nima',
    'nima?',
    'qanday',
    'qachon',
    'nega',
    'qaysi',
    'qanaqa',
    'farqi',
    'tushuntir',
    'izohla',
    'misol',
    'qoida',
    'nimaga',
    'bo\'ladi',
    'boladi',
  ];

  SavolTuri turiniTop(String s) {
    final t = s.trim();
    final arab = _arabRe.allMatches(t).length;
    final lotin = RegExp(r'[a-zA-Z]').allMatches(t).length;
    final past = t.toLowerCase();
    // Faqat SO'ROQ SO'ZI bor matn qoida savoli: «Kitob qayerda?» ham savol
    // belgisi bilan tugaydi, lekin u tarjima so'rovi.
    final savolmi = _savolSozlari.any((w) => past.contains(w));
    // Arabcha so'z bor, lekin savol o'zbekcha yozilgan («مجهول nima?») —
    // bu qoida savoli.
    if (arab > 0 && savolmi && lotin > 0) return SavolTuri.qoidaSavoli;
    if (arab > lotin) return SavolTuri.arabchaMatn;
    if (savolmi) return SavolTuri.qoidaSavoli;
    return SavolTuri.ozbekchaMatn;
  }

  Javob javob(String savol) {
    _baza.tayyorla();
    final s = savol.trim();
    if (s.isEmpty) {
      return const Javob(matn: 'Savolingizni yozing.');
    }
    return switch (turiniTop(s)) {
      SavolTuri.arabchaMatn => _arabchadan(s),
      SavolTuri.ozbekchaMatn => _ozbekchadan(s),
      SavolTuri.qoidaSavoli => _qoida(s),
    };
  }

  /// Yaqin (aynan emas, lekin so'zlari deyarli bir xil) jumla.
  /// Chegarasi 0.7: pastroq bo'lsa boshqa jumla bo'lib chiqadi.
  ({Parcha p, bool aniq})? _yaqin(String matn) {
    final m = _baza.engMos(matn);
    if (m == null) return null;
    final (p, ball) = m;
    if (ball < 0.5) return null;
    // 0.85 dan yuqori — aslida o'sha jumla (imlo farqi); pastrog'i — o'xshash.
    return (p: p, aniq: ball >= 0.85);
  }

  // ---------- 1. Arabcha → o'zbekcha ----------

  Javob _arabchadan(String matn) {
    final t = _baza.aynan(matn);
    final yaqin = t != null ? (p: t, aniq: true) : _yaqin(matn);
    final sozlar = matn
        .split(RegExp(r'\s+'))
        .where((w) => _arabRe.hasMatch(w))
        .toList();
    final tahlil = <({String ar, String uz})>[];
    for (final w in sozlar) {
      tahlil.add((ar: w, uz: _sozMa(w)));
    }
    final manbalar = _baza.qidir(matn, soni: 5);
    if (yaqin != null && yaqin.p.uz.isNotEmpty) {
      final p = yaqin.p;
      return Javob(
        matn: yaqin.aniq
            ? p.uz
            : "${p.uz}\n(kitobdagi o'xshash jumla: ${p.manba})",
        tahlil: tahlil,
        manbalar: [p, ...manbalar.where((x) => x.manba != p.manba)],
        aniq: yaqin.aniq,
      );
    }
    final sozmaSoz = tahlil
        .where((t) => !t.uz.startsWith('—'))
        .map((t) => t.uz)
        .join(' · ');
    return Javob(
      matn: sozmaSoz.isEmpty
          ? 'Bu jumla kitoblarda topilmadi va so\'zlari ham lug\'atda yo\'q.'
          : 'Kitobda aynan bunday jumla yo\'q. So\'zma-so\'z: $sozmaSoz\n'
                '(so\'zma-so\'z — gap tuzilishi emas; quyidagi tahlilga qarang)',
      tahlil: tahlil,
      manbalar: manbalar,
    );
  }

  /// Bitta arabcha so'zning ma'nosi: lug'atdan; topilmasa old qo'shimchani
  /// (وَ، بِ، لِ، فَ، الـ) ajratib qayta qidiradi.
  String _sozMa(String soz) {
    final toza = soz.replaceAll(RegExp(r'[^ء-يً-ْ]'), '');
    for (final variant in _variantlar(toza)) {
      final topildi = _baza.sozMa(variant);
      if (topildi.isNotEmpty) {
        final qism = variant == toza
            ? ''
            : ' (${_qoshimchaIzoh(toza, variant)})';
        return '${topildi.first.uz}$qism';
      }
    }
    return '— lug\'atda yo\'q';
  }

  Iterable<String> _variantlar(String soz) sync* {
    yield soz;
    final b = stripDiacritics(soz);
    if (b != soz) yield b;
    if (b.startsWith('ال') && b.length > 3) yield b.substring(2);
    for (final q in ['و', 'ف', 'ب', 'ل', 'ك']) {
      if (b.startsWith(q) && b.length > 2) {
        final qolgan = b.substring(1);
        yield qolgan;
        if (qolgan.startsWith('ال') && qolgan.length > 3) {
          yield qolgan.substring(2);
        }
      }
    }
  }

  String _qoshimchaIzoh(String toliq, String asos) {
    final b = stripDiacritics(toliq);
    final izoh = <String>[];
    if (b.startsWith('و') && !stripDiacritics(asos).startsWith('و')) {
      izoh.add('وَ — «va»');
    }
    if (b.startsWith('ب') && !stripDiacritics(asos).startsWith('ب')) {
      izoh.add('بِ — «bilan/da»');
    }
    if (b.startsWith('ل') && !stripDiacritics(asos).startsWith('ل')) {
      izoh.add('لِ — «uchun»');
    }
    if (b.contains('ال')) izoh.add('الـ — aniqlik artikli');
    return izoh.isEmpty ? 'qo\'shimcha bilan' : izoh.join(', ');
  }

  // ---------- 2. O'zbekcha → arabcha ----------

  Javob _ozbekchadan(String matn) {
    final t = _baza.aynan(matn);
    final yaqin = t != null ? (p: t, aniq: true) : _yaqin(matn);
    if (yaqin != null && yaqin.p.ar.isNotEmpty) {
      final p = yaqin.p;
      return Javob(
        matn: yaqin.aniq
            ? 'Kitobdagi jumla topildi (${p.manba}):'
            : "Aynan bunday jumla yo'q; kitobdagi eng yaqin jumla "
                  '(${p.manba}): «${p.uz}»',
        arabcha: p.ar,
        manbalar: [p, ..._baza.qidir(matn, soni: 4)],
        aniq: yaqin.aniq,
      );
    }
    // So'zma-so'z: har o'zbekcha so'zga lug'atdan arabcha juftlik.
    final sozlar = matn
        .split(RegExp(r'[^A-Za-z’‘ʻʻ\x27]+'))
        .where((w) => w.length > 1)
        .toList();
    final tahlil = <({String ar, String uz})>[];
    for (final w in sozlar) {
      final topildi = _baza.sozMa(w);
      tahlil.add((ar: topildi.isEmpty ? '—' : topildi.first.ar, uz: w));
    }
    final topilgan = tahlil.where((t) => t.ar != '—').toList();
    final manbalar = _baza.qidir(matn, soni: 5);
    if (topilgan.isEmpty) {
      return Javob(
        matn:
            'Bu jumla kitoblarda yo\'q va so\'zlari lug\'atda topilmadi.\n'
            'Kitobdagi o\'xshash joylar quyida.',
        tahlil: tahlil,
        manbalar: manbalar,
      );
    }
    return Javob(
      matn:
          'Kitobda aynan bunday jumla yo\'q. So\'zlarning kitobdagi arabchasi '
          'quyida — ularni gapga tizish uchun nahv qoidalari kerak '
          '(gap tuzilishi so\'zma-so\'z emas).',
      arabcha: topilgan.map((t) => t.ar).join(' '),
      tahlil: tahlil,
      manbalar: manbalar,
    );
  }

  // ---------- 3. Qoida savoli ----------

  Javob _qoida(String savol) {
    // Avval: kitobda AYNAN shunday jumla bormi? («Kitob qayerda?» — savol
    // belgisi bor, lekin bu grammatika savoli emas, tarjima so'rovi.)
    final t = _baza.aynan(savol);
    final yaqin = t != null ? (p: t, aniq: true) : _yaqin(savol);
    // Faqat ANIQ moslik tarjima deb qabul qilinadi: «Jazm qachon bo'ladi?»
    // ga o'xshash jumla topilib, qoida javobi o'rniga tarjima chiqmasin.
    if (yaqin != null &&
        yaqin.aniq &&
        yaqin.p.ar.isNotEmpty &&
        yaqin.p.uz.isNotEmpty) {
      final p = yaqin.p;
      return Javob(
        matn: _arabRe.hasMatch(savol)
            ? p.uz
            : 'Kitobdagi jumla topildi (${p.manba}):',
        arabcha: p.ar,
        manbalar: [p, ..._baza.qidir(savol, soni: 4)],
        aniq: true,
      );
    }
    final parchalar = _baza.qidir(savol, soni: 10);
    if (parchalar.isEmpty) {
      return const Javob(
        matn:
            'Kitoblarda bu savolga mos joy topilmadi. Savolni boshqacha '
            'yozib ko\'ring (masalan: «majhul», «jazm», «ismi foil»).',
      );
    }
    // Sharh (oddiy tildagi izoh) birinchi o'ringa chiqadi — o'quvchiga
    // avval tushunarli izoh, keyin kitob matni.
    final sharh = parchalar.where((p) => p.manba.contains('sharh')).toList();
    final kitob = parchalar.where((p) => !p.manba.contains('sharh')).toList();
    final asosiy = [...sharh, ...kitob];
    final bosh = asosiy.first;
    return Javob(
      matn: bosh.uz.isNotEmpty ? bosh.uz : bosh.ar,
      arabcha: bosh.uz.isNotEmpty ? bosh.ar : '',
      manbalar: asosiy.take(6).toList(),
      aniq: true,
    );
  }

  /// So'zning harflab yozilishi (yordamchi — ekranda ko'rsatish uchun).
  List<HarfBolagi> harflar(String soz) => harflab(soz);
}
