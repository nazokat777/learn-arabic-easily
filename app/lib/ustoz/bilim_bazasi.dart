import '../arabic.dart';
import '../content.dart';
import '../main.dart';

/// Bilim bazasidagi bitta parcha: ilovadagi kitoblarning aniq joyidan.
///
/// Ustoz bo'limi FAQAT shu parchalarga tayanadi — javob kitobdan chiqadi,
/// o'ylab topilmaydi. Har parcha qayerdanligini aytadi (manba), shuning
/// uchun o'quvchi asl darsga borib tekshira oladi.
class Parcha {
  /// Manba nomi: «Nahv 2-kitob 14-dars», «Sarf 37-dars», «Qiroat 1-12-dars».
  final String manba;

  /// Dars id (ilova ichida ochish uchun; bo'sh bo'lishi mumkin).
  final String darsId;
  final String ar;
  final String uz;

  /// Qidiruvda topilgan og'irlik (katta = mosroq).
  final double ball;
  const Parcha({
    required this.manba,
    this.darsId = '',
    this.ar = '',
    this.uz = '',
    this.ball = 0,
  });

  Parcha nusxa(double yangiBall) => Parcha(
    manba: manba,
    darsId: darsId,
    ar: ar,
    uz: uz,
    ball: yangiBall,
  );

  String get matn => [
    if (ar.isNotEmpty) ar,
    if (uz.isNotEmpty) uz,
  ].join('\n');
}

/// Ilovadagi butun kitob matni ustidan qidiradigan baza.
///
/// Bir marta yig'iladi (ro'yxat kattaligi ~20 ming parcha), keyin har
/// savolda so'z bo'yicha baholanadi. Server kerak emas: hamma narsa
/// qurilmada.
class BilimBazasi {
  BilimBazasi._();
  static final BilimBazasi instance = BilimBazasi._();

  final List<Parcha> _parchalar = [];
  bool _tayyor = false;

  /// So'z (normallashtirilgan) → shu so'z uchraydigan parcha indekslari.
  final Map<String, Set<int>> _indeks = {};

  int get soni => _parchalar.length;

  void tayyorla() {
    if (_tayyor) return;
    _qiroat();
    _nahv();
    _sarf();
    _sharh();
    _lugat();
    for (var i = 0; i < _parchalar.length; i++) {
      for (final k in _kalitlar(_parchalar[i])) {
        _indeks.putIfAbsent(k, () => <int>{}).add(i);
      }
    }
    _tayyor = true;
  }

  // ---------- yig'ish ----------

  void _qosh(Parcha p) {
    if (p.ar.trim().isEmpty && p.uz.trim().isEmpty) return;
    _parchalar.add(p);
  }

  void _qiroat() {
    for (final l in repo.qiroatLessons) {
      final manba = 'Qiroat ${l.book}-kitob ${l.num}-dars';
      final ar = splitSentences(l.reading);
      final uz = splitSentences(l.translation);
      final mos = ar.length == uz.length;
      for (var i = 0; i < ar.length; i++) {
        _qosh(
          Parcha(
            manba: manba,
            darsId: l.completionId,
            ar: ar[i],
            uz: mos ? uz[i] : '',
          ),
        );
      }
      for (final v in l.vocab) {
        _qosh(
          Parcha(
            manba: '$manba — lug\'at',
            darsId: l.completionId,
            ar: v.pl.isEmpty ? v.ar : '${v.ar} (ko\'pligi: ${v.pl})',
            uz: v.uz,
          ),
        );
      }
      for (final t in l.tables) {
        for (final r in t.rows) {
          _qosh(
            Parcha(
              manba: '$manba — ${t.title}',
              darsId: l.completionId,
              ar: r.cells.join(' · '),
              uz: r.label,
            ),
          );
        }
      }
    }
  }

  void _nahv() {
    for (final l in repo.nahvLessons) {
      final manba = 'Nahv ${l.book}-kitob ${l.num}-dars — ${l.title}';
      final id = 'nahv-${l.book}-${l.num}';
      _qosh(Parcha(manba: manba, darsId: id, ar: l.rule.ar, uz: l.rule.uz));
      for (final b in l.blocks) {
        if (b.main != null) {
          _qosh(
            Parcha(manba: manba, darsId: id, ar: b.main!.ar, uz: b.main!.uz),
          );
        }
        for (final it in b.items) {
          _qosh(Parcha(manba: manba, darsId: id, ar: it.ar, uz: it.uz));
        }
      }
      for (final e in l.exercise) {
        _qosh(
          Parcha(manba: '$manba (mashq)', darsId: id, ar: e.ar, uz: e.uz),
        );
      }
    }
  }

  void _sarf() {
    for (final l in repo.sarfLessons) {
      final manba = 'Sarf ${l.num}-dars — ${l.title}';
      final id = 'sarf-${l.num}';
      for (final b in l.blocks) {
        _qosh(Parcha(manba: manba, darsId: id, ar: b.ar, uz: b.uz));
        for (final it in b.items) {
          _qosh(Parcha(manba: manba, darsId: id, uz: it));
        }
        for (final q in b.qatorlar) {
          _qosh(Parcha(manba: manba, darsId: id, ar: q.kataklar.join(' · ')));
        }
      }
    }
  }

  void _sharh() {
    for (final e in repo.sharhlar.entries) {
      final id = e.key;
      final manba = id.startsWith('sarf-')
          ? 'Sarf ${id.split('-')[1]}-dars sharhi'
          : 'Nahv ${id.split('-')[1]}-kitob ${id.split('-')[2]}-dars sharhi';
      for (final s in e.value.sharh) {
        _qosh(Parcha(manba: manba, darsId: id, uz: s));
      }
      for (final q in e.value.savollar) {
        _qosh(
          Parcha(
            manba: '$manba (savol)',
            darsId: id,
            uz: '${q.savol}\nJavob: ${q.variantlar[q.togri]}\n${q.izoh}',
          ),
        );
      }
    }
  }

  void _lugat() {
    for (final w in repo.words) {
      _qosh(Parcha(manba: 'Lug\'at', ar: w.ar, uz: w.uz));
    }
    for (final g in repo.grammatika) {
      _qosh(Parcha(manba: 'Grammatika lug\'ati', ar: g.ar, uz: g.uz));
    }
  }

  // ---------- qidiruv ----------

  /// So'zni solishtirishga tayyorlaydi: arabchada harakat/hamza shakllari
  /// tashlanadi, o'zbekchada esa apostrof turlari va katta-kichik harf.
  static String normal(String s) {
    var t = stripDiacritics(s).toLowerCase();
    t = t
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
    t = t.replaceAll('ʻ', "'").replaceAll('‘', "'").replaceAll('’', "'");
    return t;
  }

  static List<String> sozlar(String s) => normal(s)
      .split(RegExp(r"[^ء-يa-z0-9']+"))
      .where((w) => w.length > 1)
      .toList();

  Iterable<String> _kalitlar(Parcha p) sync* {
    for (final w in sozlar('${p.ar} ${p.uz}')) {
      yield w;
      // Arabchada «al» artikli va old qo'shimchalarsiz shakl ham indekslanadi.
      if (w.startsWith('ال') && w.length > 3) yield w.substring(2);
    }
  }

  /// Savolga mos parchalar (eng moslari oldin).
  List<Parcha> qidir(String savol, {int soni = 8}) {
    tayyorla();
    final kalit = sozlar(savol).toSet();
    if (kalit.isEmpty) return const [];
    final ball = <int, double>{};
    for (final k in kalit) {
      final rowlar = <int>{
        ...?_indeks[k],
        if (k.startsWith('ال') && k.length > 3) ...?_indeks[k.substring(2)],
      };
      if (rowlar.isEmpty) continue;
      // Kam uchragan so'z qimmatroq (idf): «kitob» ko'p joyda, «majhul» kam.
      final og = 1.0 + 4.0 / (1 + rowlar.length / 40.0);
      for (final i in rowlar) {
        ball[i] = (ball[i] ?? 0) + og;
      }
    }
    if (ball.isEmpty) return const [];
    final tartib = ball.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in tartib.take(soni)) _parchalar[e.key].nusxa(e.value),
    ];
  }

  /// Aynan shu matnga (jumla yoki so'z) mos kelgan tarjima juftligi.
  /// Kitobda shunday jumla bo'lsa — tarjimasi ham kitobniki, ya'ni aniq.
  Parcha? aynan(String matn) {
    tayyorla();
    final n = normal(matn).replaceAll(RegExp(r'[^ء-يa-z0-9 ]'), '').trim();
    if (n.isEmpty) return null;
    Parcha? eng;
    for (final p in _parchalar) {
      if (p.ar.isEmpty || p.uz.isEmpty) continue;
      final pn = normal(p.ar)
          .replaceAll(RegExp(r'[^ء-يa-z0-9 ]'), '')
          .trim();
      if (pn == n) return p;
      final un = normal(p.uz)
          .replaceAll(RegExp(r'[^ء-يa-z0-9 ]'), '')
          .trim();
      if (un == n) return p;
      if (eng == null && pn.isNotEmpty && (pn.contains(n) || n.contains(pn))) {
        eng = p;
      }
    }
    return eng;
  }

  /// Bitta so'zning kitoblardagi ma'nosi (lug'at + dars lug'atlari).
  List<Parcha> sozMa(String soz) {
    tayyorla();
    final n = normal(soz);
    final chiqdi = <Parcha>[];
    for (final p in _parchalar) {
      if (p.ar.isEmpty || p.uz.isEmpty) continue;
      final bosh = normal(p.ar.split(RegExp(r'[،(]')).first).trim();
      if (bosh == n || normal(p.uz) == n) {
        chiqdi.add(p);
        if (chiqdi.length >= 4) break;
      }
    }
    return chiqdi;
  }
}
