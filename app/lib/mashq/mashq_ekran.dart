import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';

import '../main.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import 'element.dart';
import 'sessiya.dart';

/// Butun ilova uchun yagona mashq ekrani.
///
/// Ish tartibi (foydalanuvchi so'ragan tartib):
///   1) shu darsning materiali — hammasi to'g'ri javob berilmaguncha;
///   2) shu darsgacha bo'lgan hamma narsa aralash — yana toza o'tguncha.
///
/// Xato javob bergan element navbatdan chiqmaydi, 2-4 savoldan keyin
/// qaytadi. Tur oxirida xato bo'lgan bo'lsa, o'sha elementlar bilan yana
/// bir tur bo'ladi — ya'ni «bilmasdan o'tib ketish» imkoni yo'q.
class MashqEkran extends StatefulWidget {
  final String sarlavha;
  final List<MashqElement> darsniki;
  final List<MashqElement> oldingilar;

  /// Dars «o'zlashtirildi» belgisini oladigan kalit (ixtiyoriy).
  final String? darsId;

  const MashqEkran({
    super.key,
    required this.sarlavha,
    required this.darsniki,
    required this.oldingilar,
    this.darsId,
  });

  @override
  State<MashqEkran> createState() => _MashqEkranState();
}

class _MashqEkranState extends State<MashqEkran> {
  final _rnd = Random();
  late MashqSessiya _s;
  MashqSavol? _savol;

  int? _tanlangan; // tanlangan variant indeksi
  bool? _tugriMiJavob; // «to'g'rimi» savolidagi javob
  bool _javobBerildi = false;
  bool _shuSavolgaXato = false; // shu savolda xato qilindimi

  int _ketmaKet = 0; // to'g'ri javoblar ketma-ketligi (kombo)
  int _ball = 0;

  // Harflab yozish uchun: aralashtirilgan harf tugmalari va terilgani.
  List<String> _harfTugmalari = const [];
  final List<int> _terilgan = [];

  @override
  void initState() {
    super.initState();
    _s = MashqSessiya(
      darsniki: widget.darsniki,
      oldingilar: widget.oldingilar,
      rnd: _rnd,
    );
    _keyingi();
  }

  void _keyingi() {
    if (_s.bosqich == Bosqich.tugadi) {
      setState(() => _savol = null);
      return;
    }
    final s = _s.joriySavol();
    if (s == null) {
      // Savol yasab bo'lmadi — bosqichni yopamiz.
      _s.javobBer(true, birinchiUrinish: false);
      if (_s.bosqich == Bosqich.tugadi) {
        setState(() => _savol = null);
        return;
      }
      _keyingi();
      return;
    }
    setState(() {
      _savol = s;
      _tanlangan = null;
      _tugriMiJavob = null;
      _javobBerildi = false;
      _shuSavolgaXato = false;
      _terilgan.clear();
      _harfTugmalari = s.turi == MashqTuri.harflabYoz
          ? _harflarniAralashtir(s.element.ar)
          : const [];
    });
  }

  /// Harflarni aralashtiradi. Tasodifan to'g'ri tartibda chiqib qolsa
  /// (qisqa so'zda bo'lib turadi) — qayta aralashtiriladi, aks holda mashq
  /// «tugmalarni ketma-ket bosish» ga aylanib qoladi.
  List<String> _harflarniAralashtir(String ar) {
    final asl = harflarga(ar);
    if (asl.length < 2) return asl;
    var a = [...asl]..shuffle(_rnd);
    var urinish = 0;
    while (a.join() == asl.join() && urinish < 6) {
      a = [...asl]..shuffle(_rnd);
      urinish++;
    }
    return a;
  }

  void _harfBos(int i) {
    if (_javobBerildi || _terilgan.contains(i)) return;
    setState(() => _terilgan.add(i));
    final asl = harflarga(_savol!.element.ar);
    if (_terilgan.length < asl.length) return;
    final yigilgan = _terilgan.map((k) => _harfTugmalari[k]).join();
    _javob(yigilgan == asl.join());
  }

  Future<void> _javob(bool togri) async {
    if (_javobBerildi) return;
    setState(() {
      _javobBerildi = true;
      if (togri) {
        _ketmaKet++;
        // Kombo bonusi: ketma-ket to'g'ri javob ko'proq ball beradi —
        // diqqatni ushlab turadigan eng sodda va halol usul.
        _ball += 2 + (_ketmaKet ~/ 5);
      } else {
        _ketmaKet = 0;
        _shuSavolgaXato = true;
      }
    });
    togri ? Haptic.ok() : Haptic.wrong();

    final e = _savol!.element;
    await progress.bumpWord(e.kalit, togri);
    if (togri) await progress.addXp(2);

    await Future.delayed(Duration(milliseconds: togri ? 620 : 1500));
    if (!mounted) return;

    _s.javobBer(togri, birinchiUrinish: !_shuSavolgaXato);
    if (_s.bosqich == Bosqich.tugadi) {
      await _yakunla();
      return;
    }
    _keyingi();
  }

  Future<void> _yakunla() async {
    final id = widget.darsId;
    if (id != null && _s.jamiSoralgan > 0) {
      await progress.recordAttempt(id, _s.birinchidanTogri, _s.jamiSoralgan);
    }
    if (mounted) setState(() => _savol = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sarlavha),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: XpChip(value: _ball),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _savol == null ? _Yakun(s: _s) : _savolKorinishi(),
          ),
        ),
      ),
    );
  }

  Widget _savolKorinishi() {
    final s = _savol!;
    final bosqichDars = _s.bosqich == Bosqich.dars;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _bosqichIkonkasi,
                    size: 17,
                    color: bosqichDars ? AppColors.emerald : AppColors.indigo,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _bosqichNomi,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (_ketmaKet >= 3)
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: AppColors.coral,
                        ),
                        Text(
                          '$_ketmaKet',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.coral,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedBar(
                value: _s.navbat.jami == 0
                    ? 0
                    : 1 - _s.navbat.qolgan / _s.navbat.jami,
                height: 8,
                color: bosqichDars ? AppColors.emerald : AppColors.indigo,
                background: AppColors.softGreen,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: SlideSwitch(
              child: KeyedSubtree(
                key: ValueKey(
                  '${s.element.kalit}-${s.turi}-${_s.jamiSoralgan}',
                ),
                child: Column(children: [_savolKartasi(s), _javoblar(s)]),
              ),
            ),
          ),
        ),
        _fikr(s),
      ],
    );
  }

  IconData get _bosqichIkonkasi => switch (_s.bosqich) {
    Bosqich.dars => Icons.school_rounded,
    Bosqich.takror => Icons.auto_awesome_motion_rounded,
    Bosqich.yozish => Icons.edit_rounded,
    Bosqich.tugadi => Icons.check_rounded,
  };

  String get _bosqichNomi => switch (_s.bosqich) {
    Bosqich.dars => 'Shu darsning materiali',
    Bosqich.takror => 'Aralash takror — oldingi darslar ham',
    Bosqich.yozish => "Harflab yozish — o'zbekchadan arabchaga",
    Bosqich.tugadi => 'Tayyor',
  };

  Widget _savolKartasi(MashqSavol s) {
    final e = s.element;
    final String korsatma;
    switch (s.turi) {
      case MashqTuri.manoTop:
        korsatma = "Bu nima degani?";
      case MashqTuri.arabchaTop:
        korsatma = "Buning arabchasi qaysi?";
      case MashqTuri.tinglabTop:
        korsatma = "Eshiting va toping";
      case MashqTuri.tugriMi:
        korsatma = "Bu juftlik to'g'rimi?";
      case MashqTuri.harflabYoz:
        korsatma = "Arabchasini harflab yozing";
    }

    Widget ichi;
    switch (s.turi) {
      case MashqTuri.manoTop:
        ichi = _arabchaMatn(e.ar);
      case MashqTuri.arabchaTop:
        ichi = Text(
          e.uz,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        );
      case MashqTuri.tinglabTop:
        ichi = Tactile(
          child: Material(
            color: AppColors.emerald,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Tts.instance.speak(e.ovoz, id: e.kalit),
              child: const SizedBox(
                width: 84,
                height: 84,
                child: Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        );
      case MashqTuri.harflabYoz:
        ichi = Column(
          children: [
            Text(
              e.uz,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            _terilganQator(e),
          ],
        );
      case MashqTuri.tugriMi:
        ichi = Column(
          children: [
            _arabchaMatn(e.ar),
            const SizedBox(height: 10),
            const Icon(Icons.swap_vert_rounded, color: AppColors.gold),
            const SizedBox(height: 6),
            Text(
              s.variantlar.first,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        );
    }

    return Column(
      children: [
        Text(
          korsatma,
          style: const TextStyle(color: Colors.black54, fontSize: 13.5),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(child: ichi),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _arabchaMatn(String ar) => Directionality(
    textDirection: TextDirection.rtl,
    child: Text(
      ar,
      textAlign: TextAlign.center,
      style: AppTheme.arabic(size: 34, color: AppColors.emerald),
    ),
  );

  /// Terilgan harflar qatori — bo'sh kataklar bilan, o'ngdan chapga.
  /// Katakka bosilsa, o'sha joydan keyingi harflar olib tashlanadi
  /// (xato terilgan harfni tuzatish uchun).
  Widget _terilganQator(MashqElement e) {
    final jami = harflarga(e.ar).length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: List.generate(jami, (i) {
          final bor = i < _terilgan.length;
          final harf = bor ? _harfTugmalari[_terilgan[i]] : '';
          return GestureDetector(
            onTap: bor && !_javobBerildi
                ? () =>
                      setState(() => _terilgan.removeRange(i, _terilgan.length))
                : null,
            child: Container(
              width: 46,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bor ? AppColors.softGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: bor ? AppColors.emerald : Colors.black26,
                  width: bor ? 1.8 : 1.2,
                ),
              ),
              child: Text(
                harf,
                style: AppTheme.arabic(size: 26, color: AppColors.emeraldDark),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Aralashtirilgan harf tugmalari.
  Widget _harfTugmalariQatori() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: List.generate(_harfTugmalari.length, (i) {
          final ishlatilgan = _terilgan.contains(i);
          return Opacity(
            opacity: ishlatilgan ? 0.25 : 1,
            child: Tactile(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: ishlatilgan ? null : () => _harfBos(i),
                  child: Container(
                    width: 52,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold, width: 1.6),
                    ),
                    child: Text(
                      _harfTugmalari[i],
                      style: AppTheme.arabic(size: 28, color: AppColors.ink),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _javoblar(MashqSavol s) {
    if (s.turi == MashqTuri.harflabYoz) {
      return Column(
        children: [
          _harfTugmalariQatori(),
          if (_javobBerildi && _shuSavolgaXato) ...[
            const SizedBox(height: 14),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                s.element.ar,
                style: AppTheme.arabic(size: 30, color: AppColors.success),
              ),
            ),
          ],
        ],
      );
    }
    if (s.turi == MashqTuri.tugriMi) {
      return Row(
        children: [
          Expanded(
            child: _kattaTugma(
              matn: "To'g'ri",
              ikon: Icons.check_rounded,
              rang: AppColors.success,
              tanlandi: _tugriMiJavob == true,
              onTap: () {
                setState(() => _tugriMiJavob = true);
                _javob(s.juftlikTogri);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _kattaTugma(
              matn: 'Xato',
              ikon: Icons.close_rounded,
              rang: AppColors.coral,
              tanlandi: _tugriMiJavob == false,
              onTap: () {
                setState(() => _tugriMiJavob = false);
                _javob(!s.juftlikTogri);
              },
            ),
          ),
        ],
      );
    }
    return Column(
      children: [for (var i = 0; i < s.variantlar.length; i++) _variant(s, i)],
    );
  }

  Widget _kattaTugma({
    required String matn,
    required IconData ikon,
    required Color rang,
    required bool tanlandi,
    required VoidCallback onTap,
  }) {
    final korsat = _javobBerildi && tanlandi;
    return Tactile(
      child: Material(
        color: korsat ? rang.withValues(alpha: 0.15) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _javobBerildi ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: rang, width: 1.8),
            ),
            child: Column(
              children: [
                Icon(ikon, color: rang),
                const SizedBox(height: 4),
                Text(
                  matn,
                  style: TextStyle(fontWeight: FontWeight.w800, color: rang),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _variant(MashqSavol s, int i) {
    Color chegara = Colors.black12;
    Color fon = Colors.white;
    if (_javobBerildi) {
      if (i == s.togri) {
        chegara = AppColors.success;
        fon = AppColors.success.withValues(alpha: 0.10);
      } else if (i == _tanlangan) {
        chegara = AppColors.coral;
        fon = AppColors.coral.withValues(alpha: 0.10);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pulse(
        trigger: (_javobBerildi && i == s.togri) ? _s.jamiSoralgan : null,
        child: Shake(
          trigger: (_javobBerildi && i == _tanlangan && i != s.togri)
              ? _s.jamiSoralgan
              : null,
          child: Tactile(
            child: Material(
              color: fon,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _javobBerildi
                    ? null
                    : () {
                        setState(() => _tanlangan = i);
                        _javob(i == s.togri);
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: chegara, width: 1.8),
                  ),
                  child: s.arabchaVariantlar
                      ? Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            s.variantlar[i],
                            style: AppTheme.arabic(
                              size: 24,
                              color: AppColors.ink,
                            ),
                          ),
                        )
                      : Text(
                          s.variantlar[i],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fikr(MashqSavol s) {
    if (!_javobBerildi) return const SizedBox(height: 56);
    final ok = !_shuSavolgaXato;
    final rang = ok ? AppColors.success : AppColors.coral;
    final matn = ok
        ? _ketmaKet >= 5
              ? "Zo'r! $_ketmaKet ta ketma-ket"
              : "To'g'ri!"
        : s.turi == MashqTuri.tugriMi
        ? "Yo'q — ${s.element.ar} = ${s.element.uz}"
        : s.turi == MashqTuri.harflabYoz
        ? "To'g'ri yozilishi yuqorida"
        : "To'g'ri javob: ${s.variantlar[s.togri]}";
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
      alignment: Alignment.centerLeft,
      color: rang.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: rang,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              matn,
              style: TextStyle(fontWeight: FontWeight.w800, color: rang),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sessiya yakuni: natija va «qaysi joyi qiyin kelyapti» tahlili.
class _Yakun extends StatelessWidget {
  final MashqSessiya s;
  const _Yakun({required this.s});

  @override
  Widget build(BuildContext context) {
    final foiz = s.foiz;
    final mukammal = foiz >= 100;
    // Sessiyada qatnashgan elementlardan eng qiyinlari.
    final hammasi = {
      for (final e in [...s.darsniki, ...s.oldingilar]) e.kalit: e,
    }.values.toList();
    final zaiflar =
        hammasi.where((e) => progress.xatoSoni(e.kalit) > 0).toList()..sort(
          (a, b) =>
              progress.xatoSoni(b.kalit).compareTo(progress.xatoSoni(a.kalit)),
        );

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            children: [
              Reveal(
                fromScale: 0.6,
                child: GlowRing(
                  size: 132,
                  color: mukammal ? AppColors.gold : AppColors.emerald,
                  child: Float(
                    amplitude: 4,
                    child: Icon(
                      mukammal
                          ? Icons.emoji_events_rounded
                          : Icons.trending_up_rounded,
                      size: 62,
                      color: mukammal ? AppColors.gold : AppColors.emerald,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                delay: const Duration(milliseconds: 150),
                child: Text(
                  mukammal ? 'Mukammal!' : 'Mashq tugadi',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: mukammal ? AppColors.emerald : AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Reveal(
                delay: const Duration(milliseconds: 220),
                child: Text(
                  'Birinchi urinishda: ${s.birinchidanTogri} / ${s.jamiSoralgan}'
                  '  ·  $foiz%',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),
              const SizedBox(height: 18),
              const Reveal(
                delay: Duration(milliseconds: 280),
                child: OrnamentDivider(),
              ),
              const SizedBox(height: 18),
              if (zaiflar.isNotEmpty)
                Reveal(
                  delay: const Duration(milliseconds: 340),
                  child: _ZaifRoyxat(zaiflar: zaiflar.take(6).toList()),
                ),
              const SizedBox(height: 22),
              Reveal(
                delay: const Duration(milliseconds: 420),
                child: SizedBox(
                  width: double.infinity,
                  child: Tactile(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Tayyor',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (mukammal) const Positioned.fill(child: Confetti()),
      ],
    );
  }
}

/// «Sizga qiyin kelayotgan joylar» — mashqning eng foydali qismi.
///
/// O'quvchi nimani bilmasligini o'zi sezmaydi; ilova esa har javobni
/// hisoblab boradi va aynan qaysi so'z/qoida qoqilayotganini ko'rsatadi.
class _ZaifRoyxat extends StatelessWidget {
  final List<MashqElement> zaiflar;
  const _ZaifRoyxat({required this.zaiflar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_rounded,
                size: 18,
                color: AppColors.gold,
              ),
              const SizedBox(width: 6),
              const Text(
                'Sizga qiyin kelayotgan joylar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Keyingi mashqda aynan shular ko\'proq qaytadi.',
            style: TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          for (final e in zaiflar)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      e.ar,
                      style: AppTheme.arabic(size: 21, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.uz,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Text(
                    '${progress.xatoSoni(e.kalit)} xato',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.coral,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
