import '../uz_yozuv.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;
import 'package:shared_preferences/shared_preferences.dart';

import '../arabic.dart';
import '../content.dart';
import '../harflab.dart';
import '../main.dart';
import '../mashq/mukofot.dart' show Portlash;
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/uz_text.dart';
import 'gapma_gap_tarjima.dart' show TarjimaPaneli;
import 'lesson/harflab_yozish.dart';
import 'lesson/quiz_flow.dart';
import 'lesson/sentence_text.dart';

/// «Sanoq bilan yodlash» — darsning TO'LIQ matni belgilangan marta (standart
/// 33) ketma-ket chiqadi: o'quvchi har safar matnni o'qib, o'zi tarjima
/// qiladi va «O'qidim» bosadi. Sanoq darsga bog'lab saqlanadi — ertaga
/// davom etsa bo'ladi. Har 11-sanoqda va oxirida gap tekshiruvi, oxirida
/// esa dars lug'ati testi.
///
/// Raund turlari: arabcha (matn → o'zi tarjima qiladi, tarjimani ochib
/// tekshiradi) va o'zbekcha (tarjima → arabchasini o'zi aytadi, keyin
/// ochadi). «Aralash» rejimida ikkisi navbatma-navbat keladi.
class SanoqEkrani extends StatefulWidget {
  final QiroatLesson lesson;
  const SanoqEkrani({super.key, required this.lesson});

  static const maqsadlar = [7, 11, 21, 33, 50, 100];
  static const standartMaqsad = 33;

  /// Cheksiz fon harakatlari (test [pumpAndSettle] tugashi uchun o'chiriladi).
  static bool jonli = true;

  /// Har nechta sanoqda oraliq tekshiruv.
  static const tekshiruvQadami = 11;

  @override
  State<SanoqEkrani> createState() => _SanoqEkraniState();
}

enum SanoqRejim { arabcha, ozbekcha, aralash }

class _SanoqEkraniState extends State<SanoqEkrani> {
  late final List<String> _gaplar = splitSentences(widget.lesson.reading);
  int _sanoq = 0; // bajarilgan o'qishlar
  int _maqsad = SanoqEkrani.standartMaqsad;
  SanoqRejim _rejim = SanoqRejim.arabcha;
  bool _ochiq = false; // joriy raundda yashirin tomon ochilganmi
  bool _yuklandi = false;
  final _skrol = ScrollController();
  int _portlash = 0;

  String get _kalit => 'sanoq_${widget.lesson.completionId}';

  @override
  void initState() {
    super.initState();
    _yukla();
  }

  @override
  void dispose() {
    _skrol.dispose();
    Tts.instance.stop();
    super.dispose();
  }

  Future<void> _yukla() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sanoq = p.getInt('$_kalit.soni') ?? 0;
      _maqsad = p.getInt('$_kalit.maqsad') ?? SanoqEkrani.standartMaqsad;
      _rejim =
          SanoqRejim.values[(p.getInt('$_kalit.rejim') ?? 0).clamp(
            0,
            SanoqRejim.values.length - 1,
          )];
      if (_sanoq > _maqsad) _sanoq = _maqsad;
      _yuklandi = true;
    });
  }

  Future<void> _saqla() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('$_kalit.soni', _sanoq);
    await p.setInt('$_kalit.maqsad', _maqsad);
    await p.setInt('$_kalit.rejim', _rejim.index);
  }

  /// Joriy raund o'zbekcha tomondan boshlanadimi.
  bool get _ozbekchaRaund => switch (_rejim) {
    SanoqRejim.arabcha => false,
    SanoqRejim.ozbekcha => true,
    SanoqRejim.aralash => _sanoq.isOdd,
  };

  bool get _tugadi => _sanoq >= _maqsad;

  Future<void> _oqidim() async {
    if (_tugadi) return;
    Haptic.ok();
    Tts.instance.stop();
    setState(() {
      _sanoq++;
      _ochiq = false;
      if (_sanoq % SanoqEkrani.tekshiruvQadami == 0 || _sanoq >= _maqsad) {
        _portlash++;
      }
    });
    // Keyingi o'qish matn boshidan boshlanadi.
    if (_skrol.hasClients) _skrol.jumpTo(0);
    await _saqla();
    progress.addXp(1);
    final tekshiruv = _tugadi || _sanoq % SanoqEkrani.tekshiruvQadami == 0;
    if (tekshiruv && _gaplar.length >= 2 && mounted) {
      await _gapTekshiruvi();
      // Oraliq tekshiruvda 3 ta gap; hamma gap oxirida yoziladi.
      if (!_tugadi && mounted) await _harflabYoz(soni: 3);
    }
    if (_tugadi && mounted) await _yakun();
  }

  /// O'zbekcha gap → arabchasini harfma-harf yozish uchun juftlar.
  /// Har tarjima guruhi bitta topshiriq.
  List<({String ar, String uz})> get _yozishGaplari {
    final korilgan = <String>{};
    return [
      for (final g in widget.lesson.tarjimaGuruhlari)
        if (g.matn.trim().isNotEmpty &&
            g.boshi + g.soni <= _gaplar.length &&
            harflab(_guruhArabchasi(g)).length >= 2 &&
            korilgan.add(_guruhArabchasi(g)))
          (ar: _guruhArabchasi(g), uz: g.matn.trim()),
    ];
  }

  String _guruhArabchasi(TarjimaGuruh g) =>
      _gaplar.sublist(g.boshi, g.boshi + g.soni).join(' ');

  /// Darsning hamma lug'ati: o'zbekchadan arabchaga harfma-harf; fe'lning
  /// har shakli alohida topshiriq. Takror arabcha bir marta.
  List<({String ar, String uz})> get _yozishSozlari {
    final korilgan = <String>{};
    final out = <({String ar, String uz})>[];
    void qosh(String ar, String uzMatn) {
      if (harflab(ar).length >= 2 && korilgan.add(ar)) {
        out.add((ar: ar, uz: uzMatn));
      }
    }

    for (final v in widget.lesson.vocab) {
      final f = v.felShakllari;
      if (f.isEmpty) {
        for (final s in v.ar.split('=').first.split('،')) {
          qosh(s.trim(), v.uz);
        }
      } else {
        for (var i = 0; i < f.length; i++) {
          qosh(f[i], '${v.uz} — ${QiroatVocab.felShaklNomlari[i]}');
        }
      }
    }
    return out;
  }

  Future<void> _lugatYoz() async {
    final sozlar = _yozishSozlari;
    if (sozlar.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HarflabYozishEkrani.royxat(
          sozRoyxati: sozlar,
          sarlavha: "Lug'atni harflab yozish",
          gapRejimi: true,
        ),
      ),
    );
  }

  Future<void> _harflabYoz({int? soni}) async {
    var gaplar = _yozishGaplari;
    if (gaplar.isEmpty) return;
    if (soni != null && gaplar.length > soni) {
      gaplar = (gaplar..shuffle()).take(soni).toList();
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HarflabYozishEkrani.royxat(
          sozRoyxati: gaplar,
          sarlavha: "O'zbekchadan arabchaga",
          gapRejimi: true,
        ),
      ),
    );
  }

  Future<void> _gapTekshiruvi() async {
    final natija = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => _GapTekshiruvi(lesson: widget.lesson, gaplar: _gaplar),
      ),
    );
    if (natija != null && natija > 0) progress.addXp(natija * 2);
  }

  Future<void> _yakun() async {
    final bosildi = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$_maqsad marta o\'qildi!'),
        content: Text(
          'Matn $_maqsad marta o\'qib chiqildi. Endi har gap, keyin hamma '
          'lug\'at va fe\'l shakllari o\'zbekcha beriladi — arabchasini '
          'harfma-harf yozasiz. Oxirida lug\'at testi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Keyinroq'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Yozishni boshlash'),
          ),
        ],
      ),
    );
    if (bosildi == true && mounted) {
      await _harflabYoz();
      if (!mounted) return;
      await _lugatYoz();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _LugatTesti(lesson: widget.lesson)),
      );
    }
  }

  Future<void> _qaytaBoshla() async {
    final ha = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Sanoqni noldan boshlaymizmi?'),
        content: Text('Hozirgi $_sanoq / $_maqsad sanoq o\'chadi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Yo\'q'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Ha, noldan'),
          ),
        ],
      ),
    );
    if (ha == true && mounted) {
      setState(() {
        _sanoq = 0;
        _ochiq = false;
      });
      await _saqla();
    }
  }

  Future<void> _maqsadniTanla() async {
    final tanlov = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => _MaqsadTanlash(joriy: _maqsad),
    );
    if (tanlov != null && tanlov > 0 && mounted) {
      setState(() {
        _maqsad = tanlov;
        if (_sanoq > _maqsad) _sanoq = _maqsad;
      });
      await _saqla();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final ozbekcha = _ozbekchaRaund;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.deep,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Sanoq bilan yodlash — ${l.num}-dars'),
        actions: [
          IconButton(
            key: const ValueKey('sanoq-yordam'),
            tooltip: uz('Bu qanday ishlaydi?'),
            onPressed: () => _yordam(context),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          IconButton(
            tooltip: uz('Noldan boshlash'),
            onPressed: _sanoq == 0 ? null : _qaytaBoshla,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: !_yuklandi
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _sarlavha(),
                Expanded(
                  child: ListView(
                    controller: _skrol,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (_sanoq == 0 && !_tugadi) ...[
                        _tanishuvKartasi(),
                        const SizedBox(height: 14),
                      ],
                      _rejimTanlash(),
                      const SizedBox(height: 14),
                      if (_tugadi)
                        _tugadiKartasi()
                      else ...[
                        _korsatma(ozbekcha),
                        const SizedBox(height: 10),
                        _ochishTugmasi(ozbekcha),
                        const SizedBox(height: 10),
                        // O'zbekcha raundda arabchasini harfma-harf yozish.
                        if (ozbekcha && _yozishGaplari.isNotEmpty) ...[
                          FilledButton.icon(
                            key: const ValueKey('sanoq-harflab'),
                            onPressed: _harflabYoz,
                            icon: const Icon(Icons.spellcheck_rounded),
                            label: Text('Arabchasini harfma-harf yozish'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.indigo,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        SlideSwitch(
                          child: KeyedSubtree(
                            key: ValueKey('$_sanoq-$ozbekcha'),
                            child: _gapmaGap(ozbekcha),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_tugadi) _pastkiTugma(),
              ],
            ),
    );
  }

  /// Yangi o'quvchiga oddiy tilda: nima qilish kerak.
  Widget _tanishuvKartasi() {
    return Container(
      key: const ValueKey('sanoq-tanishuv'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                'Bu qanday ishlaydi?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Matnni ko'p marta takror o'qisangiz, u yodda qoladi. Bu ekran "
            "o'qishlaringizni siz uchun sanab boradi (standart: 33 marta).",
            style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          _qadam(
            1,
            "Pastdagi matnni ovoz chiqarib o'qing va o'zingiz "
            'tarjima qiling.',
          ),
          _qadam(
            2,
            "«Har gapning tarjimasini ko'rsat»ni bosib, to'g'ri aytganingizni "
            'tekshiring.',
          ),
          _qadam(
            3,
            "«O'qidim» tugmasini bosing — sanoq 1 ga oshadi. "
            "Shuni $_maqsad marta takrorlaysiz.",
          ),
          _qadam(
            4,
            "Har 11-o'qishdan keyin kichik test. Oxirida o'zbekcha gapning "
            "arabchasini harfma-harf yozasiz, keyin lug'at testi.",
          ),
          const SizedBox(height: 6),
          Text(
            "Bugun hammasini qilish shart emas: sanoq saqlanadi, ertaga "
            "qolgan joyidan davom etasiz. Nechta marta o'qishni yuqoridagi "
            "«$_maqsad marta» tugmasidan o'zgartirasiz.",
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.matn2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qadam(int n, String matn) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0B1A17),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              matn,
              style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  void _yordam(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: _tanishuvKartasi(),
      ),
    );
  }

  /// Tepadagi hero: to'q zumrad fon, suzuvchi nur va oltin sanoq halqasi.
  Widget _sarlavha() {
    final ulush = _maqsad == 0 ? 0.0 : (_sanoq / _maqsad).clamp(0.0, 1.0);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.deep, AppColors.emeraldDark],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deep.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (SanoqEkrani.jonli)
            Positioned.fill(
              child: IgnorePointer(
                child: Aurora(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.16),
                    AppColors.emerald.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 16, 20),
            child: Row(
              children: [
                Portlash(
                  trigger: _portlash == 0 ? null : _portlash,
                  child: Pulse(
                    trigger: _sanoq,
                    peak: 1.08,
                    child: _SanoqHalqasi(ulush: ulush, sanoq: _sanoq),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_sanoq / $_maqsad marta o\'qildi',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _tugadi
                            ? 'Maqsadga yetildi'
                            : 'Keyingi tekshiruv: '
                                  '${_keyingiTekshiruv()}-sanoqdan keyin',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Tactile(
                        child: InkWell(
                          key: const ValueKey('sanoq-maqsad'),
                          borderRadius: BorderRadius.circular(20),
                          onTap: _maqsadniTanla,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.goldLight.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.tune_rounded,
                                  size: 15,
                                  color: AppColors.goldLight,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_maqsad marta',
                                  style: const TextStyle(
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _keyingiTekshiruv() {
    final q = SanoqEkrani.tekshiruvQadami;
    final k = (_sanoq ~/ q + 1) * q;
    return k > _maqsad ? _maqsad : k;
  }

  /// Rejim tanlash: tanlangan bo'lak ostida sirpanuvchi oltin indikator.
  Widget _rejimTanlash() {
    const nomlar = {
      SanoqRejim.arabcha: 'Arabcha',
      SanoqRejim.ozbekcha: "O'zbekcha",
      SanoqRejim.aralash: 'Aralash',
    };
    final n = SanoqRejim.values.length;
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.karta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.chiziq2),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 420),
            curve: kExpoOut,
            alignment: Alignment(-1 + 2 * _rejim.index / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.gold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final r in SanoqRejim.values)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Haptic.tap();
                      setState(() {
                        _rejim = r;
                        _ochiq = false;
                      });
                      _saqla();
                    },
                    child: Center(
                      child: Text(
                        nomlar[r]!,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: r == _rejim
                              ? const Color(0xFF0B1A17)
                              : AppColors.matn2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _korsatma(bool ozbekcha) {
    return Text(
      ozbekcha
          ? '${_sanoq + 1}-o\'qish: o\'zbekchasini o\'qing, arabchasini '
                'o\'zingiz ayting, keyin ochib solishtiring.'
          : '${_sanoq + 1}-o\'qish: matnni ovoz chiqarib o\'qing va o\'zingiz '
                'tarjima qiling, keyin har gap tagidagi tarjimani ochib tekshiring.',
      style: TextStyle(
        fontSize: 13.5,
        color: AppColors.matn2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Matn gapma-gap: har arabcha gap tagida o'z tarjimasi. Kitobda bitta
  /// tarjima bir necha gapni qamragan bo'lsa ([TarjimaGuruh.soni] > 1), u
  /// guruhning oxirgi gapi tagida bir marta chiqadi. O'zbekcha raundda
  /// aksincha: avval tarjima, ochilganda tagida arabchasi.
  Widget _gapmaGap(bool ozbekcha) {
    final l = widget.lesson;
    Widget arabcha(int i) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SentenceText(
          key: ValueKey('sanoq-gap-$i'),
          sentence: _gaplar[i],
          vocab: l.vocab,
          reading: l.reading,
          lessonId: l.completionId,
          size: 30,
        ),
      ),
    );
    Widget tarjima(TarjimaGuruh g) => Reveal(
      key: ValueKey('sanoq-tarjima-kirish-${g.boshi}-$ozbekcha'),
      delay: Duration(milliseconds: 30 * math.min(g.boshi, 10)),
      duration: const Duration(milliseconds: 460),
      offsetY: 12,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TarjimaPaneli(
          key: ValueKey('sanoq-tarjima-${g.boshi}'),
          matn: g.matn,
          qoshimcha: g.qoshimcha,
          izoh: g.soni > 1
              ? '${g.boshi + 1}–${g.boshi + g.soni}-gaplarning tarjimasi '
                    '(kitobda birga berilgan)'
              : null,
        ),
      ),
    );

    final qatorlar = <Widget>[];
    for (var i = 0; i < _gaplar.length; i++) {
      final g = l.tarjimaGuruhi(i);
      final bor = g != null && g.matn.trim().isNotEmpty;
      if (ozbekcha) {
        if (bor && i == g.boshi) qatorlar.add(tarjima(g));
        if (_ochiq || !bor) qatorlar.add(arabcha(i));
      } else {
        qatorlar.add(arabcha(i));
        if (_ochiq && bor && i == g.boshi + g.soni - 1) {
          qatorlar.add(tarjima(g));
        }
      }
    }
    // Gapma-gap tarjimasi yo'q dars bo'lsa — kitobdagi butun tarjima.
    final butun = l.tarjimaGuruhlari.isEmpty && l.translation.trim().isNotEmpty;
    if (butun && (_ochiq || ozbekcha)) {
      qatorlar.add(TarjimaPaneli(matn: l.translation.trim()));
    }

    return Container(
      key: const ValueKey('sanoq-matn'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.karta,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deep.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  l.titleAr,
                  style: AppTheme.arabic(size: 26, color: AppColors.gold),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: uz('Butun matnni tinglash'),
                onPressed: () =>
                    Tts.instance.speak(l.reading, id: 'sanoq-matn-$_sanoq'),
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...qatorlar,
        ],
      ),
    );
  }

  /// Hamma gapning yashirin tomonini ochadi/yopadi. Matn tepasida: uzun
  /// matnda tugmani izlab pastga tushish shart emas.
  Widget _ochishTugmasi(bool ozbekcha) {
    final nomi = ozbekcha ? 'arabchasini' : 'tarjimasini';
    return OutlinedButton.icon(
      key: const ValueKey('sanoq-och'),
      onPressed: () {
        Haptic.tap();
        setState(() => _ochiq = !_ochiq);
      },
      icon: Icon(
        _ochiq ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 18,
      ),
      label: Text(_ochiq ? 'Yashirish' : "Har gapning $nomi ko'rsat"),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.indigo,
        side: const BorderSide(color: AppColors.indigo),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// Asosiy tugma: oltin gradient, nurli soya, bosilganda jonli siqilish.
  Widget _pastkiTugma() {
    final radius = BorderRadius.circular(18);
    final tugma = Tactile(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('sanoq-oqidim'),
          borderRadius: radius,
          onTap: _oqidim,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.goldLight, AppColors.gold],
              ),
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 17),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF0B1A17),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'O\'qidim — ${_sanoq + 1} / $_maqsad',
                    style: const TextStyle(
                      color: Color(0xFF0B1A17),
                      fontWeight: FontWeight.w900,
                      fontSize: 16.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SanoqEkrani.jonli
            ? Shine(borderRadius: radius, child: tugma)
            : tugma,
      ),
    );
  }

  Widget _tugadiKartasi() {
    return Reveal(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.success,
              size: 44,
            ),
            const SizedBox(height: 8),
            Text(
              'Matn $_maqsad marta o\'qildi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _LugatTesti(lesson: widget.lesson),
                    ),
                  ),
                  icon: const Icon(Icons.quiz_rounded),
                  label: Text('Lug\'at testi'),
                ),
                if (_gaplar.length >= 2)
                  OutlinedButton.icon(
                    key: const ValueKey('sanoq-harflab'),
                    onPressed: _harflabYoz,
                    icon: const Icon(Icons.spellcheck_rounded),
                    label: Text("O'zbekchadan arabchaga yozish"),
                  ),
                OutlinedButton.icon(
                  key: const ValueKey('sanoq-lugat-yoz'),
                  onPressed: _lugatYoz,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text("Lug'atni harflab yozish"),
                ),
                if (_gaplar.length >= 2)
                  OutlinedButton.icon(
                    onPressed: _gapTekshiruvi,
                    icon: const Icon(Icons.fact_check_rounded),
                    label: Text('Gap tekshiruvi'),
                  ),
                OutlinedButton.icon(
                  onPressed: _maqsadniTanla,
                  icon: const Icon(Icons.add_rounded),
                  label: Text('Maqsadni oshirish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Oltin sanoq halqasi: qiymat o'zgarganda silliq to'ladi, raqam sanab o'tadi.
class _SanoqHalqasi extends StatelessWidget {
  final double ulush;
  final int sanoq;
  const _SanoqHalqasi({required this.ulush, required this.sanoq});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: ulush),
        duration: const Duration(milliseconds: 800),
        curve: kExpoOut,
        builder: (_, q, child) =>
            CustomPaint(painter: _HalqaRassomi(q), child: child),
        child: Center(
          child: CountUp(
            key: const ValueKey('sanoq-soni'),
            value: sanoq,
            duration: const Duration(milliseconds: 500),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ),
      ),
    );
  }
}

class _HalqaRassomi extends CustomPainter {
  final double q;
  const _HalqaRassomi(this.q);

  @override
  void paint(Canvas canvas, Size size) {
    const qalin = 9.0;
    final doira = (Offset.zero & size).deflate(qalin / 2);
    canvas.drawArc(
      doira,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = qalin
        ..color = Colors.white.withValues(alpha: 0.13),
    );
    if (q <= 0) return;
    final yoy = 2 * math.pi * q;
    final shader = const SweepGradient(
      colors: [AppColors.gold, AppColors.goldLight, AppColors.gold],
      transform: GradientRotation(-math.pi / 2),
    ).createShader(doira);
    // Nur (blursiz: web'da arzon) — keng va xira chiziq.
    canvas.drawArc(
      doira,
      -math.pi / 2,
      yoy,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = qalin + 7
        ..color = AppColors.gold.withValues(alpha: 0.2),
    );
    canvas.drawArc(
      doira,
      -math.pi / 2,
      yoy,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = qalin
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_HalqaRassomi o) => o.q != q;
}

/// Maqsad tanlash varaqasi: tayyor sonlar yoki o'zi kiritadi.
class _MaqsadTanlash extends StatefulWidget {
  final int joriy;
  const _MaqsadTanlash({required this.joriy});

  @override
  State<_MaqsadTanlash> createState() => _MaqsadTanlashState();
}

class _MaqsadTanlashState extends State<_MaqsadTanlash> {
  late final _c = TextEditingController(text: '${widget.joriy}');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matn necha marta o\'qilsin?',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in SanoqEkrani.maqsadlar)
                ChoiceChip(
                  key: ValueKey('maqsad-$n'),
                  label: Text('$n'),
                  selected: widget.joriy == n,
                  onSelected: (_) => Navigator.pop(context, n),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('maqsad-kiritish'),
                  controller: _c,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'O\'zim belgilayman (1–500)',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                key: const ValueKey('maqsad-ok'),
                onPressed: () {
                  final n = int.tryParse(_c.text.trim());
                  if (n == null || n < 1 || n > 500) return;
                  Navigator.pop(context, n);
                },
                child: Text('Saqlash'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gap tekshiruvi: tarjima guruhlari bo'yicha ikki yo'nalishda 4 variantli
/// savollar — o'zbekcha → arabcha gap va arabcha → o'zbekcha tarjima.
/// Variantlar shu darsning boshqa gaplaridan olinadi.
class _GapTekshiruvi extends StatefulWidget {
  final QiroatLesson lesson;
  final List<String> gaplar;
  const _GapTekshiruvi({required this.lesson, required this.gaplar});

  @override
  State<_GapTekshiruvi> createState() => _GapTekshiruviState();
}

class _GapSavol {
  final String savol;
  final String togri;
  final List<String> variantlar;
  _GapSavol(this.savol, this.togri, this.variantlar);
}

class _GapTekshiruviState extends State<_GapTekshiruvi> {
  late final List<_GapSavol> _savollar = _tuz();
  int _i = 0;
  int _togri = 0;
  String? _tanlangan;

  List<_GapSavol> _tuz() {
    // Guruh: (arabcha matn, o'zbekcha tarjima) — tarjimasi bo'sh bo'lmagan
    // va takrorlanmaydiganlar.
    final juft = <(String, String)>[];
    for (final g in widget.lesson.tarjimaGuruhlari) {
      if (g.matn.trim().isEmpty) continue;
      if (g.boshi + g.soni > widget.gaplar.length) continue;
      final ar = widget.gaplar.sublist(g.boshi, g.boshi + g.soni).join(' ');
      if (juft.any((j) => j.$1 == ar || j.$2 == g.matn)) continue;
      juft.add((ar, g.matn));
    }
    if (juft.length < 2) return const [];
    final r = juft.toList()..shuffle();
    final savollar = <_GapSavol>[];
    for (var k = 0; k < r.length; k++) {
      final (ar, uzMatn) = r[k];
      final boshqalar = juft.where((j) => j.$1 != ar).toList()..shuffle();
      final variantlar = [uzMatn, for (final b in boshqalar.take(3)) b.$2]
        ..shuffle();
      savollar.add(_GapSavol(ar, uzMatn, variantlar));
    }
    return savollar;
  }

  void _tanla(String v) {
    if (_tanlangan != null) return;
    final togri = v == _savollar[_i].togri;
    togri ? Haptic.ok() : Haptic.wrong();
    setState(() {
      _tanlangan = v;
      if (togri) _togri++;
    });
  }

  void _keyingi() {
    if (_i + 1 >= _savollar.length) {
      Navigator.pop(context, _togri);
      return;
    }
    setState(() {
      _i++;
      _tanlangan = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_savollar.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Gap tekshiruvi')),
        body: Center(
          child: Text('Bu darsda tekshiruv uchun gaplar yetarli emas.'),
        ),
      );
    }
    final s = _savollar[_i];
    final l = widget.lesson;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Gap tekshiruvi ${_i + 1} / ${_savollar.length}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Bu gapning tarjimasi qaysi?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.matn2,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.karta,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.chiziq2),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SentenceText(
                sentence: s.savol,
                vocab: l.vocab,
                reading: l.reading,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final v in s.variantlar) ...[
            _variant(v, s),
            const SizedBox(height: 8),
          ],
          if (_tanlangan != null) ...[
            const SizedBox(height: 8),
            FilledButton(
              key: const ValueKey('gap-keyingi'),
              onPressed: _keyingi,
              child: Text(
                _i + 1 >= _savollar.length
                    ? 'Yakunlash — $_togri / ${_savollar.length}'
                    : 'Keyingi',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _variant(String v, _GapSavol s) {
    final tanlangan = _tanlangan;
    Color rang = AppColors.chiziq;
    Color? fon;
    if (tanlangan != null) {
      if (v == s.togri) {
        rang = AppColors.success;
        fon = AppColors.success.withValues(alpha: 0.1);
      } else if (v == tanlangan) {
        rang = AppColors.coral;
        fon = AppColors.coral.withValues(alpha: 0.1);
      }
    }
    return InkWell(
      key: ValueKey('gap-variant-${s.variantlar.indexOf(v)}'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => _tanla(v),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: fon ?? AppColors.karta,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: rang, width: tanlangan == null ? 1 : 1.6),
        ),
        child: Text(
          v,
          style: TextStyle(fontSize: 16, height: 1.45, color: AppColors.ink),
        ),
      ),
    );
  }
}

/// Dars lug'ati testi — darsning asosiy [QuizStage] mustaqil ekranda.
class _LugatTesti extends StatelessWidget {
  final QiroatLesson lesson;
  const _LugatTesti({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text('Lug\'at testi — ${lesson.num}-dars')),
      body: QuizStage(
        lesson: lesson,
        award: (xp) => progress.addXp(xp),
        onFinish: (missed, total) {
          final togri = total - missed.length;
          if (total > 0) {
            progress.recordAttempt(lesson.completionId, togri, total);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                missed.isEmpty
                    ? 'Hammasi to\'g\'ri — dars yodlandi!'
                    : 'Natija: $togri / $total. Xato so\'zlar: '
                          '${missed.map((v) => v.ar).join('، ')}',
              ),
            ),
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
