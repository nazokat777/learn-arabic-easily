import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, KeyEvent, KeyDownEvent, LogicalKeyboardKey;
import '../widgets/uz_text.dart';

import '../main.dart';
import '../progress.dart';
import '../screens/nishonlar_ekrani.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import 'element.dart';
import 'mukofot.dart';
import 'sessiya.dart';
import 'tovush.dart';
import 'ultra.dart';

/// Butun ilova uchun yagona mashq ekrani.
///
/// Ish tartibi:
///   1) shu darsning materiali — hammasi to'g'ri javob berilmaguncha;
///   2) «qiyin» so'zlar (3+ marta adashilganlar) — avval o'rgatib, keyin;
///   3) shu darsgacha bo'lgan hamma narsa aralash — yana toza o'tguncha;
///   4) harflab yozish.
///
/// Sessiya 8 savollik RAUNDLARGA bo'lingan: har raund oxirida bekat —
/// yulduzlar, ball, «davom / bugunga yetadi». Mantiq (navbat, xatoni
/// qaytarish, «bilmasdan o'tib ketish yo'q») o'zgarmagan; o'zgargani —
/// o'quvchi endi marrani ko'rib turadi.
class MashqEkran extends StatefulWidget {
  final String sarlavha;
  final List<MashqElement> darsniki;
  final List<MashqElement> oldingilar;

  /// Dars «o'zlashtirildi» belgisini oladigan kalit (ixtiyoriy).
  final String? darsId;

  /// Yakunda «Testga o'tish» tugmasi shuni chaqiradi (ixtiyoriy).
  final VoidCallback? testgaOt;

  /// Chaqmoq raund: shuncha soniya, bekatsiz, har ball 2×. Vaqt tugaganda
  /// yakun. Vaqt bosimi — «oqim» holatining eng tez yo'li: diqqat to'la
  /// jamlanadi, har javob qimmat, oxirida rekord bilan solishtiriladi.
  final int? tezkorSoniya;

  const MashqEkran({
    super.key,
    required this.sarlavha,
    required this.darsniki,
    required this.oldingilar,
    this.darsId,
    this.testgaOt,
    this.tezkorSoniya,
  });

  bool get tezkor => tezkorSoniya != null;

  @override
  State<MashqEkran> createState() => _MashqEkranState();
}

enum _Korinish { savol, qiyinKarta, bekat, yakun }

class _MashqEkranState extends State<MashqEkran> {
  final _rnd = Random();
  late MashqSessiya _s;
  MashqSavol? _savol;
  _Korinish _korinish = _Korinish.savol;

  int? _tanlangan; // tanlangan variant indeksi
  bool? _tugriMiJavob; // «to'g'rimi» savolidagi javob
  bool _javobBerildi = false;
  bool _shuSavolgaXato = false; // shu savolda xato qilindimi
  bool _kutilmoqda = false; // bosildi, natija hali ochilmadi
  bool _bilmadim = false; // javob ko'rsatildi (jazosiz)

  int _ketmaKet = 0; // to'g'ri javoblar ketma-ketligi (kombo)
  int _engUzunKombo = 0;
  int _ball = 0;
  int _raundBoshidagiBall = 0;
  bool _toliqTugadi = false; // «Bugunga yetadi» bilan emas, oxirigacha

  // Mukofot effektlari.
  int _portlash = 0;
  String _uchuvchiMatn = '';
  String _fikrMatni = '';
  int _daraja = progress.level;
  bool _maqsadBajarildi = false;
  Timer? _maqsadTaymeri;
  bool _rekord = false;
  Timer? _rekordTaymeri;
  int _sandiqBonus = 0; // mukammal raund sovg'asi

  // Qiyin bosqichida allaqachon o'rgatilgan elementlar.
  final Set<String> _orgatilgan = {};

  // Chaqmoq raund: qolgan soniya, vaqt tugadimi, rekord yangilandimi.
  Timer? _tezkorTaymer;
  int _qolganSoniya = 0;
  bool _vaqtTugadi = false;
  bool _chaqmoqRekord = false;

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
    if (widget.tezkor) {
      _qolganSoniya = widget.tezkorSoniya!;
      _tezkorTaymer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _korinish == _Korinish.yakun) return;
        setState(() => _qolganSoniya--);
        if (_qolganSoniya == 10) Tovush.bekat(); // «10 soniya qoldi» ishorasi
        if (_qolganSoniya <= 0) {
          _tezkorTaymer?.cancel();
          _vaqtTugadi = true;
          _toliqTugadi = false;
          _yakunla();
        }
      });
    }
    _keyingi();
  }

  @override
  void dispose() {
    _tezkorTaymer?.cancel();
    _maqsadTaymeri?.cancel();
    _rekordTaymeri?.cancel();
    Tts.instance.stop();
    super.dispose();
  }

  void _keyingi() {
    if (_s.bosqich == Bosqich.tugadi) {
      _toliqTugadi = true;
      setState(() {
        _savol = null;
        _korinish = _Korinish.yakun;
      });
      return;
    }
    final s = _s.joriySavol();
    if (s == null) {
      // Savol yasab bo'lmadi — bosqichni yopamiz.
      _s.javobBer(true, birinchiUrinish: false);
      if (_s.bosqich == Bosqich.tugadi) {
        _toliqTugadi = true;
        setState(() {
          _savol = null;
          _korinish = _Korinish.yakun;
        });
        return;
      }
      _keyingi();
      return;
    }
    // Qiyin so'z birinchi marta chiqyaptimi — avval o'rgatamiz.
    final orgat =
        _s.bosqich == Bosqich.qiyin && _orgatilgan.add(s.element.kalit);
    setState(() {
      _savol = s;
      _korinish = orgat ? _Korinish.qiyinKarta : _Korinish.savol;
      _tanlangan = null;
      _tugriMiJavob = null;
      _javobBerildi = false;
      _shuSavolgaXato = false;
      _bilmadim = false;
      _terilgan.clear();
      _harfTugmalari = s.turi == MashqTuri.harflabYoz
          ? _harflarniAralashtir(s.element.ar)
          : const [];
    });
    if (orgat && s.element.ovoz.isNotEmpty) {
      Tts.instance.speak(s.element.ovoz, id: s.element.kalit);
    }
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

  /// Mukofot hisobi: asosiy ball + kombo + tasodifiy bonus.
  ///
  /// Nega tasodifiy: doim bir xil mukofot tez «kutilgan» bo'lib qoladi
  /// va ta'siri so'nadi. Har beshinchi javobga o'xshash noaniq bonus esa
  /// miyani «yana bitta so'raymi?» deb ushlab turadi.
  (int, bool) _mukofot() {
    var ball = 2 + (_ketmaKet ~/ 5);
    var bonus = false;
    // Kunning birinchi javobi — «boshlab qo'ydingiz» bonusi: boshlangan
    // ish tashlanmaydi, birinchi qadam eng qimmati.
    if (progress.bugungiSavollar == 0) {
      ball += 3;
      bonus = true;
    }
    if (_ketmaKet == 3) ball += 1;
    if (_ketmaKet == 5) ball += 2;
    if (_ketmaKet == 10) ball += 5;
    if (_rnd.nextInt(5) == 0) {
      ball += 3;
      bonus = true;
    }
    if (widget.tezkor) ball *= 2; // chaqmoq raund: har ball ikki karra
    return (ball, bonus);
  }

  Future<void> _javob(bool togri) async {
    if (_javobBerildi || _kutilmoqda) return;
    // Kutish lahzasi: dofamin natijada emas, natijani KUTISHDA eng
    // baland. Tanlangan variant oltin rangda «o'ylab turadi», keyin
    // ochiladi — 260 ms, sezilarli lekin zeriktirmaydigan.
    setState(() => _kutilmoqda = true);
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    _kutilmoqda = false;
    var qoshildi = 0;
    var bonus = false;
    setState(() {
      _javobBerildi = true;
      if (togri) {
        _ketmaKet++;
        _engUzunKombo = max(_engUzunKombo, _ketmaKet);
        (qoshildi, bonus) = _mukofot();
        _ball += qoshildi;
        _portlash++;
        _uchuvchiMatn = bonus ? '+$qoshildi bonus!' : '+$qoshildi';
        _fikrMatni = Maqtov.togri(_rnd, ketmaKet: _ketmaKet, bonus: bonus);
      } else {
        _ketmaKet = 0;
        _shuSavolgaXato = true;
        _fikrMatni = Maqtov.xato(_rnd);
      }
    });
    togri ? Haptic.ok() : Haptic.wrong();
    togri ? Tovush.togri(_ketmaKet) : Tovush.xato();

    final e = _savol!.element;
    await progress.bumpWord(e.kalit, togri);
    // Kunlik maqsadga aynan shu javob bilan yetildimi — bir martalik
    // mukofot. Xato javob ham hisobga kiradi: maqsad «ishlash», «to'g'ri
    // topish» emas — aks holda qiynalgan kun jazoga aylanadi.
    if (await progress.kunlikMukofotniOl()) {
      _ball += Progress.kunlikMukofotBalli;
      if (mounted) setState(() => _maqsadBajarildi = true);
      _maqsadTaymeri?.cancel();
      _maqsadTaymeri = Timer(const Duration(milliseconds: 3200), () {
        if (mounted) setState(() => _maqsadBajarildi = false);
      });
    }
    var darajaOshdi = false;
    if (togri) {
      await progress.addXp(qoshildi);
      if (progress.level > _daraja) {
        _daraja = progress.level;
        darajaOshdi = true;
      }
      if (await progress.rekordniYangila(_ketmaKet)) {
        if (mounted) setState(() => _rekord = true);
        _rekordTaymeri?.cancel();
        _rekordTaymeri = Timer(const Duration(milliseconds: 2600), () {
          if (mounted) setState(() => _rekord = false);
        });
      }
    }

    await Future.delayed(Duration(milliseconds: togri ? 700 : 1500));
    if (!mounted) return;
    // Daraja — butun ekranli lahza; o'quvchi o'zi yopadi.
    if (darajaOshdi) {
      Tovush.daraja();
      await darajaOynasi(
        context,
        nom: progress.levelName,
        daraja: progress.level,
      );
      if (!mounted) return;
    }

    final oldingiBosqich = _s.bosqich;
    _s.javobBer(togri, birinchiUrinish: !_shuSavolgaXato);
    if (_s.bosqich == Bosqich.tugadi) {
      _toliqTugadi = true;
      await _yakunla();
      return;
    }
    // Raund to'ldi yoki bosqich almashdi — bekat.
    if (_s.raundTugadi ||
        (_s.bosqich != oldingiBosqich && _s.raunddaSoralgan >= 3)) {
      if (widget.tezkor) {
        _davom(); // chaqmoqda bekat yo'q — vaqt ketyapti
        return;
      }
      _sandiqBonus = _s.raundYulduzi == 3
          ? XazinaSandigi.tasodifiyBonus(_rnd)
          : 0;
      Tovush.bekat();
      setState(() => _korinish = _Korinish.bekat);
      return;
    }
    _keyingi();
  }

  /// «Bilmadim» — taxmin qilish o'rniga halol javob. Jazo yo'q: xato
  /// sanalmaydi, seriya uzilmaydi; lekin element navbatga qaytadi va
  /// tur «toza» hisoblanmaydi — o'rganish shart, o'tib ketish yo'q.
  Future<void> _bilmadimBos() async {
    if (_javobBerildi || _kutilmoqda) return;
    final s = _savol!;
    setState(() {
      _javobBerildi = true;
      _shuSavolgaXato = true;
      _bilmadim = true;
      _fikrMatni = "Mana to'g'ri javob — eslab qoling";
    });
    Haptic.tap();
    if (s.element.ovoz.isNotEmpty) {
      Tts.instance.speak(s.element.ovoz, id: s.element.kalit);
    }
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    final oldingiBosqich = _s.bosqich;
    _s.javobBer(false, birinchiUrinish: false);
    if (_s.bosqich == Bosqich.tugadi) {
      _toliqTugadi = true;
      await _yakunla();
      return;
    }
    if (_s.raundTugadi ||
        (_s.bosqich != oldingiBosqich && _s.raunddaSoralgan >= 3)) {
      if (widget.tezkor) {
        _davom();
        return;
      }
      _sandiqBonus = 0;
      Tovush.bekat();
      setState(() => _korinish = _Korinish.bekat);
      return;
    }
    _keyingi();
  }

  void _davom() {
    _raundBoshidagiBall = _ball;
    _s.yangiRaund();
    _keyingi();
  }

  Future<void> _yakunla() async {
    final id = widget.darsId;
    // O'zlashtirish belgisi faqat sessiya OXIRIGACHA o'tilganda: «bugunga
    // yetadi» deb chiqib ketgan sessiya ham natija emas, dam olish.
    if (id != null && _toliqTugadi && _s.jamiSoralgan > 0) {
      await progress.recordAttempt(id, _s.birinchidanTogri, _s.jamiSoralgan);
    }
    if (widget.tezkor) {
      _tezkorTaymer?.cancel();
      _chaqmoqRekord = await progress.chaqmoqRekordniYangila(
        _s.birinchidanTogri,
      );
    }
    if (mounted) {
      setState(() {
        _savol = null;
        _korinish = _Korinish.yakun;
      });
    }
    // Yangi nishon ochilgan bo'lsa — yakun ko'ringach marosim.
    final yangi = await progress.yangiNishonlar();
    if (yangi.isNotEmpty && mounted) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) await nishonOynasi(context, yangi);
    }
  }

  /// Klaviatura: 1–4 variantni tanlaydi, T/X — «to'g'rimi» savolida,
  /// Enter/bo'sh joy — bekatda «Davom». Kompyuterda mashq sichqonchasiz
  /// ketadi — tezlik o'z-o'zidan «oqim» holatini beradi.
  void _tugma(KeyEvent e) {
    if (e is! KeyDownEvent) return;
    final k = e.logicalKey;
    if (_korinish == _Korinish.bekat) {
      if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) {
        _davom();
      }
      return;
    }
    if (_korinish == _Korinish.qiyinKarta) {
      if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) {
        setState(() => _korinish = _Korinish.savol);
      }
      return;
    }
    final s = _savol;
    if (s == null || _korinish != _Korinish.savol || _javobBerildi) return;
    if (k == LogicalKeyboardKey.keyB) {
      _bilmadimBos();
      return;
    }
    if (s.turi == MashqTuri.tugriMi) {
      if (k == LogicalKeyboardKey.keyT || k == LogicalKeyboardKey.digit1) {
        setState(() => _tugriMiJavob = true);
        _javob(s.juftlikTogri);
      } else if (k == LogicalKeyboardKey.keyX ||
          k == LogicalKeyboardKey.digit2) {
        setState(() => _tugriMiJavob = false);
        _javob(!s.juftlikTogri);
      }
      return;
    }
    if (s.turi == MashqTuri.harflabYoz) return;
    const raqamlar = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
    ];
    final i = raqamlar.indexOf(k);
    if (i < 0 || i >= s.variantlar.length) return;
    setState(() => _tanlangan = i);
    _javob(i == s.togri);
  }

  /// Keycap belgilarini faqat klaviaturali (keng) ekranda ko'rsatamiz.
  bool _keycap(BuildContext context) => MediaQuery.sizeOf(context).width >= 700;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        _tugma(e);
        return KeyEventResult.ignored;
      },
      child: Scaffold(
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
        // Bosqich rangi fonda yumshoq nur bo'lib turadi: dars — zumrad,
        // qiyin — marjon, takror — binafsha, yozish — oltin. Bosqich
        // almashganda rang erib o'tadi — o'quvchi «boshqa joyga keldim»ni
        // o'qimasdan sezadi.
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _bosqichRangi.withValues(alpha: 0.16),
                _bosqichRangi.withValues(alpha: 0.0),
              ],
              stops: const [0, 0.45],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Kunlik maqsad bajarilgan lahza — bir marta konfetti.
                if (_maqsadBajarildi)
                  const Positioned.fill(
                    child: IgnorePointer(child: Confetti(count: 110)),
                  ),
                Column(
                  children: [
                    if (widget.tezkor && _korinish != _Korinish.yakun)
                      VaqtChizigi(
                        qolgan: _qolganSoniya,
                        jami: widget.tezkorSoniya!,
                      ),
                    if (_maqsadBajarildi)
                      const MaqsadBanner(ball: Progress.kunlikMukofotBalli),
                    if (_rekord)
                      MukofotBanner(
                        ikon: Icons.military_tech_rounded,
                        matn: 'Yangi rekord: $_ketmaKet ta ketma-ket!',
                      ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: switch (_korinish) {
                            _Korinish.yakun => _Yakun(
                              s: _s,
                              nom: widget.sarlavha,
                              toliq: _toliqTugadi,
                              engUzunKombo: _engUzunKombo,
                              testgaOt: widget.testgaOt,
                              tezkor: widget.tezkor,
                              vaqtTugadi: _vaqtTugadi,
                              ball: _ball,
                              chaqmoqRekord: _chaqmoqRekord,
                            ),
                            _Korinish.bekat => RaundBekati(
                              raund: _s.raundRaqami,
                              yulduz: _s.raundYulduzi,
                              togri: _s.raunddaTogri,
                              jami: _s.raunddaSoralgan,
                              ball: _ball - _raundBoshidagiBall,
                              engUzunKombo: _engUzunKombo,
                              keyingiNomi: _bosqichQisqaNomi,
                              sandiq: _sandiqBonus > 0
                                  ? XazinaSandigi(
                                      bonus: _sandiqBonus,
                                      onOchildi: () {
                                        Tovush.sandiq();
                                        setState(() => _ball += _sandiqBonus);
                                        progress.addXp(_sandiqBonus);
                                      },
                                    )
                                  : null,
                              onDavom: _davom,
                              onYetadi: () {
                                _toliqTugadi = false;
                                _yakunla();
                              },
                            ),
                            _Korinish.qiyinKarta => QiyinKarta(
                              ar: _savol!.element.ar,
                              uz: _savol!.element.uz,
                              xatoSoni: progress.xatoSoni(
                                _savol!.element.kalit,
                              ),
                              onOvoz: () => Tts.instance.speak(
                                _savol!.element.ovoz,
                                id: _savol!.element.kalit,
                              ),
                              onTayyor: () =>
                                  setState(() => _korinish = _Korinish.savol),
                            ),
                            _Korinish.savol => _savolKorinishi(),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _savolKorinishi() {
    final s = _savol!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(_bosqichIkonkasi, size: 17, color: _bosqichRangi),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _bosqichNomi,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  KomboOlov(ketmaKet: _ketmaKet),
                ],
              ),
              const SizedBox(height: 8),
              SegmentliBar(
                jami: MashqSessiya.raundHajmi,
                tolgan: _s.raunddaSoralgan,
                rang: _bosqichRangi,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  KomboMarra(ketmaKet: _ketmaKet),
                  const Spacer(),
                  Text(
                    '${_s.raundRaqami}-raund · '
                    '${MashqSessiya.raundHajmi - _s.raunddaSoralgan} ta qoldi',
                    style: TextStyle(fontSize: 11.5, color: AppColors.matn3),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
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

  Color get _bosqichRangi => switch (_s.bosqich) {
    Bosqich.dars => AppColors.emerald,
    Bosqich.qiyin => AppColors.coral,
    Bosqich.takror => AppColors.indigo,
    Bosqich.yozish => AppColors.gold,
    Bosqich.tugadi => AppColors.emerald,
  };

  IconData get _bosqichIkonkasi => switch (_s.bosqich) {
    Bosqich.dars => Icons.school_rounded,
    Bosqich.qiyin => Icons.psychology_rounded,
    Bosqich.takror => Icons.auto_awesome_motion_rounded,
    Bosqich.yozish => Icons.edit_rounded,
    Bosqich.tugadi => Icons.check_rounded,
  };

  String get _bosqichNomi => switch (_s.bosqich) {
    Bosqich.dars => 'Shu darsning materiali',
    Bosqich.qiyin => "Qiyin so'zlar ustida",
    Bosqich.takror => 'Aralash takror — oldingi darslar ham',
    Bosqich.yozish => "Harflab yozish — o'zbekchadan arabchaga",
    Bosqich.tugadi => 'Tayyor',
  };

  String get _bosqichQisqaNomi => switch (_s.bosqich) {
    Bosqich.dars => 'dars',
    Bosqich.qiyin => "qiyin so'zlar",
    Bosqich.takror => 'takror',
    Bosqich.yozish => 'yozish',
    Bosqich.tugadi => 'yakun',
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
          style: TextStyle(
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
              style: TextStyle(
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
              style: TextStyle(
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
          style: TextStyle(color: AppColors.matn2, fontSize: 13.5),
        ),
        const SizedBox(height: 12),
        KomboNur(
          ketmaKet: _ketmaKet,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: AppColors.karta,
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
              // Uchuvchi «+N» — karta tepasidan ko'tariladi.
              Positioned(
                top: -6,
                child: UchuvchiBall(
                  trigger: _portlash == 0 ? null : _portlash,
                  matn: _uchuvchiMatn,
                  rang: _uchuvchiMatn.contains('bonus')
                      ? AppColors.indigo
                      : AppColors.gold,
                ),
              ),
            ],
          ),
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
                  color: bor ? AppColors.emerald : AppColors.chiziq,
                  width: bor ? 1.8 : 1.2,
                ),
              ),
              child: Text(
                harf,
                style: AppTheme.arabic(size: 26, color: AppColors.zumradMatn),
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
                color: AppColors.karta,
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
      return Portlash(
        trigger: (_javobBerildi && !_shuSavolgaXato) ? _portlash : null,
        child: Column(
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
        ),
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
    final togriBosildi = korsat && !_shuSavolgaXato;
    return Portlash(
      trigger: togriBosildi ? _portlash : null,
      child: Tactile(
        child: Material(
          color: korsat ? rang.withValues(alpha: 0.15) : AppColors.karta,
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
      ),
    );
  }

  Widget _variant(MashqSavol s, int i) {
    Color chegara = AppColors.chiziq2;
    Color fon = AppColors.karta;
    if (_kutilmoqda && i == _tanlangan) {
      chegara = AppColors.gold;
      fon = AppColors.gold.withValues(alpha: 0.10);
    }
    if (_javobBerildi) {
      if (i == s.togri) {
        chegara = AppColors.success;
        fon = AppColors.success.withValues(alpha: 0.10);
      } else if (i == _tanlangan) {
        chegara = AppColors.coral;
        fon = AppColors.coral.withValues(alpha: 0.10);
      }
    }
    final togriBosildi = _javobBerildi && i == s.togri && !_shuSavolgaXato;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Portlash(
        trigger: togriBosildi ? _portlash : null,
        child: Pulse(
          trigger: (_javobBerildi && i == s.togri) ? _s.jamiSoralgan : null,
          peak: togriBosildi ? 1.08 : 1.04,
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
                  onTap: (_javobBerildi || _kutilmoqda)
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
                    child: Row(
                      children: [
                        Expanded(
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                        ),
                        if (_keycap(context))
                          Container(
                            margin: const EdgeInsets.only(left: 10),
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.chiziq),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.matn3,
                              ),
                            ),
                          ),
                      ],
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
    if (!_javobBerildi) {
      return SizedBox(
        height: 56,
        child: Center(
          child: TextButton.icon(
            onPressed: _kutilmoqda ? null : _bilmadimBos,
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            label: Text(
              _keycap(context)
                  ? "Bilmadim — javobni ko'rsat (B)"
                  : "Bilmadim — javobni ko'rsat",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          ),
        ),
      );
    }
    final ok = !_shuSavolgaXato;
    final rang = ok
        ? AppColors.success
        : (_bilmadim ? AppColors.gold : AppColors.coral);
    final izoh = ok
        ? null
        : s.turi == MashqTuri.tugriMi
        ? "${s.element.ar} = ${s.element.uz}"
        : s.turi == MashqTuri.harflabYoz
        ? "To'g'ri yozilishi yuqorida"
        : "To'g'ri javob: ${s.variantlar[s.togri]}";
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
      alignment: Alignment.centerLeft,
      color: rang.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Reveal(
            fromScale: 0.4,
            offsetY: 0,
            duration: const Duration(milliseconds: 420),
            child: Icon(
              ok
                  ? Icons.check_circle_rounded
                  : (_bilmadim
                        ? Icons.lightbulb_rounded
                        : Icons.cancel_rounded),
              color: rang,
              size: 26,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fikrMatni,
                  style: TextStyle(fontWeight: FontWeight.w800, color: rang),
                ),
                if (izoh != null)
                  Text(
                    izoh,
                    style: TextStyle(
                      color: rang.withValues(alpha: 0.85),
                      fontSize: 13,
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

/// Sessiya yakuni: natija va «qaysi joyi qiyin kelyapti» tahlili.
class _Yakun extends StatelessWidget {
  final MashqSessiya s;
  final String nom;
  final bool toliq;
  final int engUzunKombo;
  final VoidCallback? testgaOt;
  final bool tezkor;
  final bool vaqtTugadi;
  final int ball;
  final bool chaqmoqRekord;
  const _Yakun({
    required this.s,
    required this.nom,
    required this.toliq,
    required this.engUzunKombo,
    this.testgaOt,
    this.tezkor = false,
    this.vaqtTugadi = false,
    this.ball = 0,
    this.chaqmoqRekord = false,
  });

  @override
  Widget build(BuildContext context) {
    final foiz = s.foiz;
    final mukammal = toliq && foiz >= 100;
    // Sessiyada qatnashgan elementlardan eng qiyinlari.
    final hammasi = {
      for (final e in [...s.darsniki, ...s.oldingilar]) e.kalit: e,
    }.values.toList();
    final zaiflar =
        hammasi.where((e) => progress.xatoSoni(e.kalit) > 0).toList()..sort(
          (a, b) =>
              progress.xatoSoni(b.kalit).compareTo(progress.xatoSoni(a.kalit)),
        );
    final qiyinlar = zaiflar.where((e) => progress.qiyinMi(e.kalit)).toList();
    final sarlavha = tezkor
        ? (chaqmoqRekord
              ? 'Yangi chaqmoq rekordi!'
              : vaqtTugadi
              ? 'Vaqt tugadi!'
              : 'Chaqmoq raund tugadi')
        : mukammal
        ? 'Mukammal!'
        : toliq
        ? 'Mashq tugadi'
        : 'Yaxshi dam oling';
    final izoh = tezkor
        ? "${s.birinchidanTogri} ta to'g'ri  ·  +$ball ball (2×)"
              "${chaqmoqRekord ? '' : '  ·  rekord: ${progress.chaqmoqRekord}'}"
        : toliq
        ? 'Birinchi urinishda: ${s.birinchidanTogri} / ${s.jamiSoralgan}'
              '  ·  $foiz%'
        : "${s.jamiSoralgan} ta savol yechildi. O'zlashtirish belgisi "
              "uchun mashqni oxirigacha o'ting.";

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
                  color: mukammal || chaqmoqRekord
                      ? AppColors.gold
                      : tezkor
                      ? AppColors.amber
                      : AppColors.emerald,
                  child: Float(
                    amplitude: 4,
                    child: Icon(
                      tezkor
                          ? Icons.bolt_rounded
                          : mukammal
                          ? Icons.emoji_events_rounded
                          : toliq
                          ? Icons.trending_up_rounded
                          : Icons.self_improvement_rounded,
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
                  sarlavha,
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
                  izoh,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.matn2, fontSize: 14),
                ),
              ),
              if (engUzunKombo >= 3) ...[
                const SizedBox(height: 8),
                Reveal(
                  delay: const Duration(milliseconds: 260),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.coral,
                        size: 18,
                      ),
                      Text(
                        ' Eng uzun seriya: $engUzunKombo',
                        style: const TextStyle(
                          color: AppColors.coral,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Reveal(
                delay: Duration(milliseconds: 300),
                child: BugunChizigi(),
              ),
              const SizedBox(height: 14),
              const Reveal(
                delay: Duration(milliseconds: 320),
                child: OrnamentDivider(),
              ),
              const SizedBox(height: 18),
              if (zaiflar.isNotEmpty)
                Reveal(
                  delay: const Duration(milliseconds: 340),
                  child: _ZaifRoyxat(zaiflar: zaiflar.take(6).toList()),
                ),
              // Shu sessiyada «qiyin» bo'lib qolganlar bo'lsa — ularni
              // darrov alohida mashq qilish imkoni. Aynan qiynalgan paytda
              // taklif qilinsa, o'quvchi uni kechiktirmaydi.
              if (qiyinlar.isNotEmpty) ...[
                const SizedBox(height: 12),
                Reveal(
                  delay: const Duration(milliseconds: 380),
                  child: SizedBox(
                    width: double.infinity,
                    child: Tactile(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MashqEkran(
                              sarlavha: "Qiyin so'zlar",
                              darsniki: qiyinlar,
                              oldingilar: hammasi,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.psychology_rounded, size: 20),
                        label: Text(
                          "Qiyin so'zlar ustida ishlash (${qiyinlar.length})",
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.coral,
                          side: const BorderSide(color: AppColors.coral),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              // Natijani kursdoshlarga yuborish — ijtimoiy motivatsiya:
              // guruhda o'qiganda «men ham qildim» eng kuchli turtki.
              Reveal(
                delay: const Duration(milliseconds: 380),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      final matn =
                          "Arab tili — $nom: ${s.birinchidanTogri}/"
                          "${s.jamiSoralgan} to'g'ri ($foiz%), eng uzun seriya "
                          "$engUzunKombo. Bugun ${progress.bugungiSavollar} savol, "
                          "${progress.streak} kun ketma-ket.";
                      await Clipboard.setData(ClipboardData(text: matn));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Natija nusxalandi — kursdoshlarga yuboring!',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text(
                      'Natijani ulashish',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.emerald,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (testgaOt != null) ...[
                Reveal(
                  delay: const Duration(milliseconds: 400),
                  child: SizedBox(
                    width: double.infinity,
                    child: Tactile(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          testgaOt!();
                        },
                        icon: const Icon(Icons.quiz_rounded),
                        label: const Text(
                          "Testga o'tish",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Reveal(
                delay: const Duration(milliseconds: 420),
                child: SizedBox(
                  width: double.infinity,
                  child: Tactile(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: testgaOt != null
                            ? AppColors.emeraldDark
                            : AppColors.emerald,
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

  /// So'z varag'i — qiyin so'zga bosilsa: katta arabcha, ma'no, ovoz.
  /// Yakundagi ro'yxat shunchaki hisobot emas, o'rganish nuqtasi.
  void _sozVaragi(BuildContext context, MashqElement e) {
    if (e.ovoz.isNotEmpty) Tts.instance.speak(e.ovoz, id: e.kalit);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.karta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.chiziq2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                e.ar,
                textAlign: TextAlign.center,
                style: AppTheme.arabic(
                  size: 40,
                  color: AppColors.emerald,
                  w: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const OrnamentDivider(),
            const SizedBox(height: 10),
            Text(
              e.uz,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${e.modul} · ${progress.xatoSoni(e.kalit)} marta adashilgan',
              style: TextStyle(fontSize: 12.5, color: AppColors.matn2),
            ),
            const SizedBox(height: 16),
            Tactile(
              child: Material(
                color: AppColors.emerald,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Tts.instance.speak(e.ovoz, id: e.kalit),
                  child: const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          Text(
            'Keyingi mashqda aynan shular ko\'proq qaytadi.',
            style: TextStyle(fontSize: 12.5, color: AppColors.matn2),
          ),
          const SizedBox(height: 10),
          for (final e in zaiflar)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _sozVaragi(context, e),
              child: Padding(
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
                        style: TextStyle(
                          color: AppColors.matn2,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Text(
                      progress.qiyinMi(e.kalit)
                          ? 'qiyin'
                          : '${progress.xatoSoni(e.kalit)} xato',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
