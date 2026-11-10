import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../arabic.dart';
import '../content.dart';
import '../harflab.dart';
import '../main.dart';
import '../mashq/mukofot.dart';
import '../mashq/tovush.dart';
import '../rasm.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/speak_button.dart';
import '../widgets/uz_text.dart';
import 'bosh_joy.dart';
import 'lesson/qiyin_sozlar.dart';

/// Savol turlari — ilgari alohida o'yin bo'lgan mashqlar endi bitta
/// oqimda aralash so'raladi: miya har savolda «qaysi yo'l bilan
/// eslash kerak»ni o'zi tanlaydi (interleaving) — bitta turni ketma-ket
/// takrorlashdan ko'ra mustahkamroq yodlatadi.
enum AralashTur {
  manoTop, // arabcha (+ovoz) → o'zbekcha
  arabchaTop, // o'zbekcha → arabcha
  rasmTop, // rasm → arabcha
  tinglab, // faqat ovoz → arabcha
  koplik, // birlik → ko'plik
  birlikTop, // ko'plik → birligi
  boshJoy, // jumladagi bo'sh joy
  juftlash, // 4 juftni moslash
  harflab, // harflardan so'z yig'ish
  jumlaTuz, // tinglab jumla tuzish
  yozma, // o'zbekcha → arabchasini klaviaturada yozish (variantsiz)
  tezkor, // vaqtli: «bu juftlik to'g'rimi?»
}

class AralashSavol {
  final AralashTur tur;
  final QiroatVocab? v;
  final List<String> variantlar;
  final String togri;

  /// Harflab / jumla: to'g'ri ketma-ketlik va aralashtirilgan bo'laklar.
  final List<String> tartib;
  final List<String> bolaklar;
  final BoshJoy? bj;
  final List<QiroatVocab> juftlar;
  final String jumla;

  /// Harflab: ko'pligi so'raladimi.
  final bool koplikMi;

  const AralashSavol({
    required this.tur,
    this.v,
    this.variantlar = const [],
    this.togri = '',
    this.tartib = const [],
    this.bolaklar = const [],
    this.bj,
    this.juftlar = const [],
    this.jumla = '',
    this.koplikMi = false,
  });
}

/// Savollar to'plamini yasaydi (UI'siz — test qilinadi).
class AralashYasagich {
  final QiroatLesson lesson;
  final Random rnd;

  /// Faqat shu so'zlar so'raladi (bo'sh bo'lsa — darsning hamma so'zi).
  final List<QiroatVocab> faqat;

  AralashYasagich(this.lesson, {Random? rnd, this.faqat = const []})
    : rnd = rnd ?? Random();

  static String bosh(QiroatVocab v) => splitForms(v.ar).first;

  static String kalit(QiroatLesson l, QiroatVocab v) =>
      QiyinTanlov.kalit(l.completionId, v);

  List<QiroatVocab> get darsSozlari {
    final seen = <String>{};
    return [
      for (final v in lesson.vocab)
        if (v.ar.trim().isNotEmpty &&
            v.uz.trim().isNotEmpty &&
            !bosh(v).contains(' ') &&
            seen.add(v.uz))
          v,
    ];
  }

  /// Chalg'ituvchilar havzasi: shu dars va oldingi darslar lug'ati.
  late final List<QiroatVocab> havza = () {
    final r = [...darsSozlari];
    try {
      final chegara = lesson.book * 1000 + lesson.num;
      for (final l in repo.qiroatLessons) {
        if (l.book * 1000 + l.num >= chegara) continue;
        r.addAll(l.vocab.where((v) => v.ar.trim().isNotEmpty));
      }
    } catch (_) {}
    return r;
  }();

  List<String> _variant(String togri, Iterable<String> nomzod, int n) {
    final boshqa = nomzod.where((s) => s.trim().isNotEmpty).toSet()
      ..remove(togri);
    final ro = boshqa.toList()..shuffle(rnd);
    if (ro.length < n - 1) return const [];
    return [togri, ...ro.take(n - 1)]..shuffle(rnd);
  }

  AralashSavol? _bitta(AralashTur t, QiroatVocab v, {bool? koplikga}) {
    final ar = bosh(v);
    final uzlar = havza
        .where((x) => x.uz.trim() != v.uz.trim())
        .map((x) => x.uz);
    final arlar = havza.where((x) => x.uz.trim() != v.uz.trim()).map(bosh);
    switch (t) {
      case AralashTur.manoTop:
        final o = _variant(v.uz, uzlar, 4);
        return o.isEmpty
            ? null
            : AralashSavol(tur: t, v: v, variantlar: o, togri: v.uz);
      case AralashTur.arabchaTop:
      case AralashTur.tinglab:
        final o = _variant(ar, arlar, 4);
        return o.isEmpty
            ? null
            : AralashSavol(tur: t, v: v, variantlar: o, togri: ar);
      case AralashTur.rasmTop:
        if (Rasm.topish(v.uz) == null) return null;
        final o = _variant(ar, arlar, 4);
        return o.isEmpty
            ? null
            : AralashSavol(tur: t, v: v, variantlar: o, togri: ar);
      case AralashTur.koplik:
        final sh = v.plShakllari;
        if (sh.isEmpty) return null;
        final nomzod = <String>[
          for (final x in havza)
            for (final p in x.plShakllari)
              if (!sh.contains(p)) p,
        ];
        if (nomzod.toSet().length < 3) {
          nomzod.addAll(arlar.where((a) => a != ar));
        }
        final o = _variant(sh.first, nomzod, 4);
        return o.isEmpty
            ? null
            : AralashSavol(tur: t, v: v, variantlar: o, togri: sh.first);
      case AralashTur.birlikTop:
        final sh = v.plShakllari;
        if (sh.isEmpty) return null;
        final o = _variant(ar, [
          for (final x in havza)
            if (x.plShakllari.isNotEmpty && bosh(x) != ar) bosh(x),
          ...arlar,
        ], 4);
        return o.isEmpty
            ? null
            : AralashSavol(
                tur: t,
                v: v,
                variantlar: o,
                togri: ar,
                jumla: sh.first,
              );
      case AralashTur.harflab:
        final pl = v.plShakllari.where((p) => !p.contains(' ')).toList();
        final koplikMi = pl.isNotEmpty && (koplikga ?? rnd.nextBool());
        final soz = koplikMi ? pl.first : ar;
        final tartib = [for (final h in harflab(soz)) h.shakl];
        if (tartib.length < 2 || tartib.length > 9) return null;
        // Ikki begona harf — taxmin bilan emas, eslab yig'ilsin.
        final begona = <String>{
          for (final x in havza.take(40))
            for (final h in harflab(bosh(x))) h.shakl,
        }..removeAll(tartib);
        final qosh = (begona.toList()..shuffle(rnd)).take(2);
        return AralashSavol(
          tur: t,
          v: v,
          togri: soz,
          tartib: tartib,
          bolaklar: [...tartib, ...qosh]..shuffle(rnd),
          koplikMi: koplikMi,
        );
      case AralashTur.yozma:
        final pl = v.plShakllari.where((p) => !p.contains(' ')).toList();
        final koplikMi = pl.isNotEmpty && (koplikga ?? rnd.nextBool());
        final soz = koplikMi ? pl.first : ar;
        if (soz.contains(' ')) return null;
        return AralashSavol(tur: t, v: v, togri: soz, koplikMi: koplikMi);
      case AralashTur.tezkor:
        final togriMi = rnd.nextBool();
        final boshqa = uzlar.toSet().toList()..shuffle(rnd);
        if (!togriMi && boshqa.isEmpty) return null;
        return AralashSavol(
          tur: t,
          v: v,
          jumla: togriMi ? v.uz : boshqa.first,
          togri: togriMi ? 'ha' : 'yoq',
        );
      case AralashTur.boshJoy:
      case AralashTur.juftlash:
      case AralashTur.jumlaTuz:
        return null;
    }
  }

  /// So'z uchun ikki xil tur — biri tanish, biri faol eslash.
  List<AralashSavol> _sozSavollari(QiroatVocab v) {
    final oson = [
      AralashTur.manoTop,
      AralashTur.tinglab,
      AralashTur.tezkor,
      if (Rasm.topish(v.uz) != null) AralashTur.rasmTop,
    ]..shuffle(rnd);
    final qiyin = [
      AralashTur.arabchaTop,
      AralashTur.harflab,
      AralashTur.yozma,
      if (v.plShakllari.isNotEmpty) AralashTur.koplik,
    ]..shuffle(rnd);
    final r = <AralashSavol>[];
    for (final ro in [oson, qiyin]) {
      for (final t in ro) {
        final s = _bitta(t, v);
        if (s != null) {
          r.add(s);
          break;
        }
      }
    }
    // Ko'pligi bor so'zda birlik-ko'plik juftligi uch tomondan so'raladi:
    // birligidan ko'pligi, ko'pligidan birligi, ko'pligini harflab yig'ish.
    if (v.plShakllari.isNotEmpty) {
      for (final t in [AralashTur.koplik, AralashTur.birlikTop]) {
        if (r.any((s) => s.tur == t)) continue;
        final s = _bitta(t, v);
        if (s != null) r.add(s);
      }
      if (!r.any((s) => s.koplikMi)) {
        final s = _bitta(AralashTur.harflab, v, koplikga: true);
        if (s != null) r.add(s);
      }
    }
    return r;
  }

  List<AralashSavol> _boshJoylar(Set<String> sozlar) {
    final hammasi = BoshJoy.yasa(lesson);
    final r = <AralashSavol>[];
    for (final b in hammasi) {
      if (!sozlar.contains(b.lugat.ar)) continue;
      final o = _variant(b.soz, [
        for (final x in hammasi) x.soz,
        for (final x in havza.take(30)) bosh(x),
      ], 4);
      if (o.isNotEmpty) {
        r.add(
          AralashSavol(
            tur: AralashTur.boshJoy,
            v: b.lugat,
            bj: b,
            variantlar: o,
            togri: b.soz,
          ),
        );
      }
    }
    return r;
  }

  List<AralashSavol> _jumlalar(int n) {
    final r = <AralashSavol>[];
    final jj = splitSentences(lesson.reading)..shuffle(rnd);
    for (final j in jj) {
      final sozlar = [
        for (final t in tokenize(j))
          if (t.isWord) t.text,
      ];
      if (sozlar.length < 3 || sozlar.length > 7) continue;
      if (sozlar.toSet().length != sozlar.length) continue;
      r.add(
        AralashSavol(
          tur: AralashTur.jumlaTuz,
          jumla: j,
          tartib: sozlar,
          bolaklar: [...sozlar]..shuffle(rnd),
        ),
      );
      if (r.length >= n) break;
    }
    return r;
  }

  /// Butun mashq: qiyin (tanlangan) so'zlar oldin, keyin zaiflari.
  List<AralashSavol> yasa() {
    final tanlangan = QiyinTanlov.sozlar(lesson.completionId);
    var sozlar = faqat.isNotEmpty ? [...faqat] : [...darsSozlari];
    if (faqat.isEmpty) {
      final t = {for (final v in tanlangan) v.ar};
      sozlar.sort((a, b) {
        final x = (t.contains(b.ar) ? 1 : 0).compareTo(
          t.contains(a.ar) ? 1 : 0,
        );
        if (x != 0) return x;
        return progress
            .zaiflik(kalit(lesson, b))
            .compareTo(progress.zaiflik(kalit(lesson, a)));
      });
    }
    sozlar = sozlar.where((v) => !bosh(v).contains(' ')).toList();

    final r = <AralashSavol>[];
    for (final v in sozlar) {
      r.addAll(_sozSavollari(v));
    }
    // Ikki bloklik aralashtirish: qiyinlar boshda qoladi, lekin turlar
    // ketma-ket bir xil kelmaydi.
    final bosh0 = r.take(r.length ~/ 2).toList()..shuffle(rnd);
    final oxir = r.skip(r.length ~/ 2).toList()..shuffle(rnd);
    final natija = [...bosh0, ...oxir];

    final qoshimcha = <AralashSavol>[
      ..._boshJoylar({for (final v in sozlar) v.ar}).take(4),
      if (faqat.isEmpty) ..._jumlalar(2),
    ];
    // Juftlash — har 4 so'zga bitta.
    for (var i = 0; i + 4 <= sozlar.length && i < 16; i += 4) {
      final j = sozlar.sublist(i, i + 4);
      if (j.map((x) => x.uz).toSet().length == 4) {
        qoshimcha.add(AralashSavol(tur: AralashTur.juftlash, juftlar: j));
      }
    }
    for (final q in qoshimcha) {
      final o = natija.isEmpty ? 0 : 2 + rnd.nextInt(natija.length - 1);
      natija.insert(min(o, natija.length), q);
    }
    return natija;
  }
}

class AralashMashqEkrani extends StatefulWidget {
  final QiroatLesson lesson;

  /// Faqat shu so'zlar (masalan «Qiyin so'zlarim»).
  final List<QiroatVocab> faqat;
  final String sarlavha;
  const AralashMashqEkrani({
    super.key,
    required this.lesson,
    this.faqat = const [],
    this.sarlavha = 'Aralash mashq',
  });

  @override
  State<AralashMashqEkrani> createState() => _AralashMashqEkraniState();
}

class _AralashMashqEkraniState extends State<AralashMashqEkrani> {
  final _rnd = Random();
  late List<AralashSavol> _navbat;
  int _jami = 0;
  int _togriSoni = 0;
  int _ketma = 0;
  int _portlash = 0;
  final Map<String, QiroatVocab> _xatolar = {};
  final Map<AralashSavol, int> _qaytgan = {};

  // Joriy savol holati.
  String? _tanlangan;
  bool? _natija; // null — javob hali yo'q
  String _fikr = '';
  final List<int> _terilgan = [];
  String _yozuv = '';
  Timer? _taymer;
  int _qolgan = 0; // tezkor: qolgan o'ndan-soniyalar
  static const _tezkorVaqt = 60; // 6 soniya
  String? _juftAr;
  final Set<String> _juftlangan = {};
  final Set<String> _juftXato = {};
  String? _juftQizil;

  QiroatLesson get _l => widget.lesson;
  AralashSavol? get _s => _navbat.isEmpty ? null : _navbat.first;

  /// Joriy savol (test uchun).
  AralashSavol? get joriy => _s;

  @override
  void initState() {
    super.initState();
    _boshla();
  }

  void _boshla() {
    _navbat = AralashYasagich(_l, rnd: _rnd, faqat: widget.faqat).yasa();
    _jami = _navbat.length;
    _togriSoni = 0;
    _xatolar.clear();
    _qaytgan.clear();
    _tozala();
    WidgetsBinding.instance.addPostFrameCallback((_) => _avtoOvoz());
  }

  void _tozala() {
    _tanlangan = null;
    _natija = null;
    _fikr = '';
    _terilgan.clear();
    _yozuv = '';
    _taymer?.cancel();
    _taymer = null;
    _juftAr = null;
    _juftlangan.clear();
    _juftXato.clear();
    _juftQizil = null;
  }

  void _avtoOvoz() {
    final s = _s;
    if (s == null || !mounted) return;
    switch (s.tur) {
      case AralashTur.manoTop:
      case AralashTur.tinglab:
        Tts.instance.speak(AralashYasagich.bosh(s.v!), id: 'ar-savol');
      case AralashTur.jumlaTuz:
        Tts.instance.speak(s.jumla, id: 'ar-savol');
      case AralashTur.tezkor:
        Tts.instance.speak(AralashYasagich.bosh(s.v!), id: 'ar-savol');
        _qolgan = _tezkorVaqt;
        _taymer = Timer.periodic(const Duration(milliseconds: 100), (t) {
          if (!mounted || _natija != null) return t.cancel();
          setState(() => _qolgan--);
          if (_qolgan <= 0) {
            t.cancel();
            _yakunla(false);
          }
        });
      default:
        break;
    }
  }

  @override
  void dispose() {
    _taymer?.cancel();
    Tts.instance.stop();
    super.dispose();
  }

  Future<void> _yakunla(bool ok, {String? ovoz}) async {
    final s = _s!;
    ok ? Haptic.ok() : Haptic.wrong();
    ok ? Tovush.togri(_ketma + 1) : Tovush.xato();
    setState(() {
      _natija = ok;
      if (ok) {
        _ketma++;
        _portlash++;
        if (!_qaytgan.containsKey(s)) _togriSoni++;
        _fikr = Maqtov.togri(_rnd, ketmaKet: _ketma);
      } else {
        _ketma = 0;
        _fikr = Maqtov.xato(_rnd);
        if (s.v != null) _xatolar[s.v!.ar] = s.v!;
      }
    });
    if (ovoz != null) Tts.instance.speak(ovoz, id: 'ar-javob');
    if (s.tur != AralashTur.juftlash && s.v != null) {
      await progress.bumpWord(AralashYasagich.kalit(_l, s.v!), ok);
    }
    if (ok) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted && _natija == true && identical(_s, s)) _keyingi();
    }
  }

  void _keyingi() {
    final s = _navbat.removeAt(0);
    // Xato savol 3 savoldan keyin qaytadi (ko'pi bilan ikki marta).
    if (_natija == false && (_qaytgan[s] ?? 0) < 2) {
      _qaytgan[s] = (_qaytgan[s] ?? 0) + 1;
      _navbat.insert(min(3, _navbat.length), s);
    }
    setState(_tozala);
    _avtoOvoz();
  }

  void _variant(String o) {
    if (_natija != null) return;
    final s = _s!;
    setState(() => _tanlangan = o);
    final arabcha = s.tur != AralashTur.manoTop;
    _yakunla(
      o == s.togri,
      ovoz: s.tur == AralashTur.boshJoy
          ? s.bj!.jumla
          : (arabcha ? s.togri : null),
    );
  }

  /// Harakatsiz, hamza shakllari bir xil — yozma imtihondagi qoida.
  static String _norm(String s) {
    var t = stripDiacritics(s);
    t = t.replaceAll(RegExp('[أإآٱ]'), 'ا').replaceAll('ى', 'ي');
    t = t.replaceAll(RegExp(r'[^ء-ي\s]'), ' ');
    return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).join(' ');
  }

  void _yozmaTekshir() {
    if (_natija != null || _yozuv.trim().isEmpty) return;
    final s = _s!;
    _yakunla(_norm(_yozuv) == _norm(s.togri), ovoz: s.togri);
  }

  void _tezkorJavob(bool ha) {
    if (_natija != null) return;
    _taymer?.cancel();
    final s = _s!;
    _yakunla(ha == (s.togri == 'ha'), ovoz: AralashYasagich.bosh(s.v!));
  }

  void _bolak(int i) {
    final s = _s!;
    if (_natija != null || _terilgan.contains(i)) return;
    Haptic.tap();
    setState(() => _terilgan.add(i));
    if (_terilgan.length == s.tartib.length) {
      final ok =
          [for (final k in _terilgan) s.bolaklar[k]].join('|') ==
          s.tartib.join('|');
      _yakunla(ok, ovoz: s.tur == AralashTur.jumlaTuz ? s.jumla : s.togri);
    }
  }

  void _juft(String tomon, QiroatVocab v) {
    final s = _s!;
    if (_natija != null || _juftlangan.contains(v.ar)) return;
    if (tomon == 'ar') {
      Haptic.tap();
      Tts.instance.speak(AralashYasagich.bosh(v), id: 'juft');
      setState(() {
        _juftAr = v.ar;
        _juftQizil = null;
      });
      return;
    }
    final tanlangan = _juftAr;
    if (tanlangan == null) return;
    if (tanlangan == v.ar) {
      Haptic.ok();
      setState(() {
        _juftlangan.add(v.ar);
        _juftAr = null;
      });
      progress.bumpWord(
        AralashYasagich.kalit(_l, v),
        !_juftXato.contains(v.ar),
      );
      if (_juftlangan.length == s.juftlar.length) {
        _yakunla(_juftXato.isEmpty);
      }
    } else {
      Haptic.wrong();
      Tovush.xato();
      final w = s.juftlar.firstWhere((x) => x.ar == tanlangan);
      _xatolar[w.ar] = w;
      setState(() {
        _juftXato.add(tanlangan);
        _juftQizil = v.ar;
        _juftAr = null;
      });
    }
  }

  // ------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sarlavha),
        actions: [
          if (widget.faqat.isEmpty)
            IconButton(
              key: const ValueKey('aralash-qiyin'),
              tooltip: "Qiyin so'zlarim",
              icon: const Icon(Icons.flag_rounded),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QiyinSozlarEkrani(lesson: _l),
                  ),
                );
                if (mounted) setState(_boshla);
              },
            ),
        ],
      ),
      body: s == null ? _yakun() : _savolKorinishi(s),
    );
  }

  Widget _savolKorinishi(AralashSavol s) {
    final bajarildi = _jami == 0 ? 0.0 : 1 - _navbat.length / _jami;
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: AnimatedBar(
                value: bajarildi.clamp(0, 1).toDouble(),
                height: 8,
                color: AppColors.emerald,
                background: AppColors.softGreen,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: KeyedSubtree(
                  key: ValueKey(identityHashCode(s)),
                  child: _tana(s),
                ),
              ),
            ),
            if (_natija != null) _pastki(s),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Portlash(trigger: _portlash, child: const SizedBox.expand()),
          ),
        ),
      ],
    );
  }

  /// Har tur o'z rangida — o'yinlar ro'yxatidagi ranglar.
  Color _rang(AralashTur t) => switch (t) {
    AralashTur.manoTop ||
    AralashTur.rasmTop ||
    AralashTur.juftlash => Color(0xFF16A34A),
    AralashTur.arabchaTop || AralashTur.harflab => Color(0xFF7C3AED),
    AralashTur.koplik || AralashTur.birlikTop => Color(0xFFEC4899),
    AralashTur.tinglab ||
    AralashTur.boshJoy ||
    AralashTur.jumlaTuz => Color(0xFF2563EB),
    AralashTur.yozma => Color(0xFF0891B2),
    AralashTur.tezkor => Color(0xFFF97316),
  };

  String _korsatma(AralashSavol s) => switch (s.tur) {
    AralashTur.manoTop => "Ma'nosi qaysi?",
    AralashTur.arabchaTop => 'Arabchasi qaysi?',
    AralashTur.rasmTop => 'Rasmdagi narsa arabchada qanday?',
    AralashTur.tinglab => 'Eshiting — qaysi so\'z?',
    AralashTur.koplik => "Ko'pligi qaysi?",
    AralashTur.birlikTop => "Bu ko'plik — birligi qaysi?",
    AralashTur.boshJoy => "Bo'sh joyga qaysi so'z?",
    AralashTur.juftlash => 'Juftini toping: avval arabchasini bosing',
    AralashTur.harflab =>
      s.koplikMi ? "Ko'pligini harflab yig'ing" : "Arabchasini harflab yig'ing",
    AralashTur.jumlaTuz => "Eshiting va jumlani tuzing",
    AralashTur.yozma =>
      s.koplikMi ? "Ko'pligini o'zingiz yozing" : "Arabchasini o'zingiz yozing",
    AralashTur.tezkor => "Tez! Bu juftlik to'g'rimi?",
  };

  Widget _arabcha(String t, {double size = 34, Color? rang}) => Directionality(
    textDirection: TextDirection.rtl,
    child: Text(
      t,
      textAlign: TextAlign.center,
      style: AppTheme.arabic(
        size: size,
        color: rang ?? AppColors.ink,
        w: FontWeight.w700,
      ),
    ),
  );

  Widget _uz(String t, {double size = 24}) => Text(
    t,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: AppColors.ink,
    ),
  );

  Widget _tana(AralashSavol s) {
    final v = s.v;
    final ustki = <Widget>[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _rang(s.tur),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          _korsatma(s),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];
    switch (s.tur) {
      case AralashTur.manoTop:
        ustki.addAll([
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpeakButton(text: AralashYasagich.bosh(v!), id: 'ar-s', size: 22),
              const SizedBox(width: 8),
              Flexible(child: _arabcha(AralashYasagich.bosh(v), size: 40)),
            ],
          ),
        ]);
      case AralashTur.arabchaTop:
        ustki.add(_uz(v!.uz));
      case AralashTur.rasmTop:
        ustki.addAll([
          Text(Rasm.topish(v!.uz)!, style: const TextStyle(fontSize: 72)),
          if (_natija != null) _uz(v.uz, size: 18),
        ]);
      case AralashTur.tinglab:
        ustki.add(
          SpeakButton(text: AralashYasagich.bosh(v!), id: 'ar-s', size: 44),
        );
      case AralashTur.koplik:
        ustki.addAll([
          _arabcha(AralashYasagich.bosh(v!), size: 36),
          const SizedBox(height: 4),
          Text(
            '${v.uz} — birligi',
            style: TextStyle(color: AppColors.matn3, fontSize: 13),
          ),
        ]);
      case AralashTur.birlikTop:
        ustki.addAll([
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpeakButton(text: s.jumla, id: 'ar-s', size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: _arabcha(s.jumla, size: 36, rang: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${v!.uz} — ko'pligi",
            style: TextStyle(color: AppColors.matn3, fontSize: 13),
          ),
        ]);
      case AralashTur.boshJoy:
        final b = s.bj!;
        final joy = _natija == null ? ' ______ ' : ' ${b.soz} ';
        ustki.add(_arabcha('${b.oldi}$joy${b.keyin}', size: 26));
      case AralashTur.juftlash:
        return Column(children: [...ustki, _juftlash(s)]);
      case AralashTur.harflab:
        ustki.addAll([
          _uz(s.koplikMi ? "${v!.uz} — KO'PLIGI" : v!.uz),
          const SizedBox(height: 14),
          _terilganQator(s),
          const SizedBox(height: 16),
          _bolaklar(s),
        ]);
        return Column(children: ustki);
      case AralashTur.jumlaTuz:
        ustki.addAll([
          SpeakButton(text: s.jumla, id: 'ar-s', size: 36),
          const SizedBox(height: 14),
          _terilganQator(s),
          const SizedBox(height: 16),
          _bolaklar(s),
        ]);
        return Column(children: ustki);
      case AralashTur.yozma:
        ustki.addAll([
          _uz(s.koplikMi ? "${v!.uz} — KO'PLIGI" : v!.uz),
          const SizedBox(height: 14),
          _yozmaQism(s),
        ]);
        return Column(children: ustki);
      case AralashTur.tezkor:
        ustki.addAll([
          LinearProgressIndicator(
            value: (_qolgan / _tezkorVaqt).clamp(0, 1).toDouble(),
            minHeight: 8,
            color: _rang(s.tur),
            backgroundColor: _rang(s.tur).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 20),
          _arabcha(AralashYasagich.bosh(v!), size: 40),
          const SizedBox(height: 6),
          const Icon(Icons.swap_vert_rounded),
          _uz(s.jumla),
          const SizedBox(height: 22),
          Row(
            children: [
              for (final (ha, nom, rang) in [
                (false, "Noto'g'ri", const Color(0xFFEC4899)),
                (true, "To'g'ri", const Color(0xFF16A34A)),
              ]) ...[
                Expanded(
                  child: FilledButton(
                    key: ValueKey(ha ? 'tez-ha' : 'tez-yoq'),
                    onPressed: () => _tezkorJavob(ha),
                    style: FilledButton.styleFrom(
                      backgroundColor: rang,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (!ha) const SizedBox(width: 12),
              ],
            ],
          ),
        ]);
        return Column(children: ustki);
    }
    return Column(
      children: [
        ...ustki,
        const SizedBox(height: 22),
        for (final o in s.variantlar) _variantTugma(s, o),
      ],
    );
  }

  Widget _variantTugma(AralashSavol s, String o) {
    final arabcha = s.tur != AralashTur.manoTop;
    Color chegara = _rang(s.tur).withValues(alpha: 0.55);
    Color? fon = _rang(s.tur).withValues(alpha: 0.06);
    if (_natija != null && o == s.togri) {
      chegara = AppColors.success;
      fon = AppColors.success.withValues(alpha: 0.12);
    } else if (_natija == false && o == _tanlangan) {
      chegara = AppColors.coral;
      fon = AppColors.coral.withValues(alpha: 0.12);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          key: ValueKey('variant-$o'),
          onPressed: () => _variant(o),
          style: OutlinedButton.styleFrom(
            backgroundColor: fon,
            side: BorderSide(color: chegara, width: 1.6),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: arabcha
              ? _arabcha(o, size: 26)
              : Text(
                  o,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _terilganQator(AralashSavol s) {
    final jumla = s.tur == AralashTur.jumlaTuz;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.karta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _natija == null
              ? AppColors.chiziq2
              : (_natija! ? AppColors.success : AppColors.coral),
          width: 1.6,
        ),
      ),
      child: Column(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: jumla ? 8 : 2,
              children: [
                for (final k in _terilgan)
                  Text(
                    s.bolaklar[k],
                    style: AppTheme.arabic(size: 28, color: AppColors.ink),
                  ),
              ],
            ),
          ),
          if (_natija == false) ...[
            const SizedBox(height: 6),
            Text(
              "To'g'risi:",
              style: TextStyle(fontSize: 12, color: AppColors.matn3),
            ),
            _arabcha(
              jumla ? s.jumla : s.togri,
              size: 26,
              rang: AppColors.success,
            ),
          ],
          if (_natija == null && _terilgan.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const ValueKey('ochir'),
                icon: const Icon(Icons.backspace_outlined),
                onPressed: () => setState(_terilgan.removeLast),
              ),
            ),
        ],
      ),
    );
  }

  static const _harflar = [
    'ا',
    'ب',
    'ت',
    'ث',
    'ج',
    'ح',
    'خ',
    'د',
    'ذ',
    'ر',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ع',
    'غ',
    'ف',
    'ق',
    'ك',
    'ل',
    'م',
    'ن',
    'ه',
    'و',
    'ي',
    'ة',
    'ء',
    'ى',
    'أ',
    'إ',
    'آ',
    'ؤ',
    'ئ',
  ];
  static const _harakatlar = ['َ', 'ِ', 'ُ', 'ْ', 'ّ', 'ً', 'ٍ', 'ٌ'];

  /// To'liq arab klaviaturasi — variant yo'q, o'zi eslab yozadi.
  Widget _yozmaQism(AralashSavol s) {
    final rang = _rang(s.tur);
    Widget tugma(
      String h,
      VoidCallback f, {
      String? key,
      bool harakat = false,
    }) => Material(
      color: harakat ? rang.withValues(alpha: 0.12) : rang,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: ValueKey(key ?? 'harf-$h'),
        borderRadius: BorderRadius.circular(10),
        onTap: _natija != null ? null : f,
        child: SizedBox(
          width: 40,
          height: 44,
          child: Center(
            child: Text(
              harakat ? '◌$h' : h,
              style: AppTheme.arabic(
                size: 22,
                color: harakat ? rang : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
    return Column(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.karta,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _natija == null
                  ? rang
                  : (_natija! ? AppColors.success : AppColors.coral),
              width: 1.6,
            ),
          ),
          child: _arabcha(_yozuv.isEmpty ? ' ' : _yozuv, size: 32),
        ),
        const SizedBox(height: 12),
        if (_natija == null) ...[
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final h in _harflar)
                  tugma(h, () => setState(() => _yozuv += h)),
                for (final h in _harakatlar)
                  tugma(h, () => setState(() => _yozuv += h), harakat: true),
                tugma('⌫', () {
                  if (_yozuv.isEmpty) return;
                  setState(
                    () => _yozuv = _yozuv.substring(0, _yozuv.length - 1),
                  );
                }, key: 'yozma-ochir'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('yozma-tekshir'),
              onPressed: _yozmaTekshir,
              icon: const Icon(Icons.check_rounded),
              label: Text('Tekshirish'),
              style: FilledButton.styleFrom(
                backgroundColor: rang,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _yakunla(false, ovoz: s.togri),
            child: Text("Bilmadim — javobni ko'rsat"),
          ),
        ],
      ],
    );
  }

  Widget _bolaklar(AralashSavol s) => Directionality(
    textDirection: TextDirection.rtl,
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (i, b) in s.bolaklar.indexed)
          Opacity(
            opacity: _terilgan.contains(i) ? 0.25 : 1,
            child: OutlinedButton(
              key: ValueKey('bolak-$i'),
              onPressed: () => _bolak(i),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(52, 52),
                backgroundColor: _rang(s.tur),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                b,
                style: AppTheme.arabic(size: 26, color: Colors.white),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _juftlash(AralashSavol s) {
    final uzlar = [...s.juftlar]
      ..sort((a, b) => a.uz.hashCode.compareTo(b.uz.hashCode));
    Widget katak(String tomon, QiroatVocab v) {
      final tayyor = _juftlangan.contains(v.ar);
      final tanlangan = tomon == 'ar' && _juftAr == v.ar;
      final qizil = tomon == 'uz' && _juftQizil == v.ar;
      return Padding(
        padding: const EdgeInsets.all(4),
        child: OutlinedButton(
          key: ValueKey('juft-$tomon-${v.ar}'),
          onPressed: tayyor ? null : () => _juft(tomon, v),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            backgroundColor: tayyor
                ? AppColors.success.withValues(alpha: 0.15)
                : tanlangan
                ? AppColors.gold.withValues(alpha: 0.2)
                : qizil
                ? AppColors.coral.withValues(alpha: 0.15)
                : AppColors.karta,
            side: BorderSide(
              color: tanlangan ? AppColors.gold : AppColors.chiziq2,
              width: tanlangan ? 2 : 1,
            ),
          ),
          child: tomon == 'ar'
              ? _arabcha(AralashYasagich.bosh(v), size: 22)
              : Text(
                  v.uz,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(children: [for (final v in uzlar) katak('uz', v)]),
        ),
        Expanded(
          child: Column(children: [for (final v in s.juftlar) katak('ar', v)]),
        ),
      ],
    );
  }

  Widget _pastki(AralashSavol s) {
    final ok = _natija!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      color: (ok ? AppColors.success : AppColors.coral).withValues(alpha: 0.12),
      child: Column(
        children: [
          Text(
            _fikr,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ok ? AppColors.success : AppColors.coral,
            ),
          ),
          if (!ok && s.v != null) ...[
            const SizedBox(height: 6),
            _arabcha(
              [AralashYasagich.bosh(s.v!), ...s.v!.plShakllari].join('  ،  '),
              size: 22,
            ),
            Text(s.v!.uz, style: TextStyle(color: AppColors.matn2)),
          ],
          if (!ok) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('davom'),
                onPressed: _keyingi,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Tushundim — davom'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _yakun() {
    final foiz = _jami == 0 ? 0 : (_togriSoni * 100 / _jami).round();
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 20),
        Icon(Icons.emoji_events_rounded, size: 72, color: AppColors.gold),
        const SizedBox(height: 10),
        _uz(
          _jami == 0
              ? "Bu darsda so'raladigan so'z yo'q"
              : '$foiz% birinchi urinishda',
        ),
        const SizedBox(height: 6),
        Text(
          '$_jami ta savol',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.matn2),
        ),
        if (_xatolar.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            "Adashilgan so'zlar — qiyin so'zlarimga qo'shing:",
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          for (final v in _xatolar.values) _XatoQatori(lesson: _l, v: v),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('qayta'),
          onPressed: () => setState(_boshla),
          icon: const Icon(Icons.replay_rounded),
          label: Text('Yana aralash mashq'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.emerald,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Chiqish'),
        ),
      ],
    );
  }
}

class _XatoQatori extends StatefulWidget {
  final QiroatLesson lesson;
  final QiroatVocab v;
  const _XatoQatori({required this.lesson, required this.v});

  @override
  State<_XatoQatori> createState() => _XatoQatoriState();
}

class _XatoQatoriState extends State<_XatoQatori> {
  @override
  Widget build(BuildContext context) {
    final id = widget.lesson.completionId;
    final bor = QiyinTanlov.bormi(id, widget.v);
    return Card(
      child: ListTile(
        title: Text(widget.v.uz),
        subtitle: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            [
              AralashYasagich.bosh(widget.v),
              ...widget.v.plShakllari,
            ].join(' ، '),
            style: AppTheme.arabic(size: 20, color: AppColors.ink),
          ),
        ),
        trailing: IconButton(
          key: ValueKey('xato-qiyin-${widget.v.ar}'),
          icon: Icon(
            bor ? Icons.flag_rounded : Icons.outlined_flag_rounded,
            color: bor ? AppColors.gold : AppColors.matn3,
          ),
          onPressed: () async {
            await QiyinTanlov.almashtir(id, widget.v);
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }
}
