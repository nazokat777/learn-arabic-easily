import 'dart:math';

import 'package:flutter/material.dart';

import '../content.dart';
import '../main.dart';
import '../services/tts.dart';
import '../theme.dart';

/// Nahv darsidan keyingi interaktiv test — Duolingo uslubida.
///
/// Nega kerak: darsni faqat O'QIB chiqish yodda qoldirmaydi. Test darsdagi
/// arabcha-o'zbekcha juftliklardan avtomatik tuziladi va uch xil savol
/// beradi: arabchasini ko'rib ma'nosini topish, ma'nosidan arabchasini
/// topish va faqat ESHITIB ma'nosini topish.
///
/// Eng muhim qoidasi — xato qilingan savol yo'qolmaydi: u navbat oxiriga
/// qaytib qo'shiladi va TO'G'RI javob berilmaguncha test tugamaydi.
/// Shuning uchun xotirasi eng past o'quvchi ham darsni yodlab chiqadi —
/// shunchaki bir necha marta ko'proq urinadi.
///
/// O'ZLASHTIRISH SHARTI: dars faqat butun test BITTA HAM xatosiz
/// o'tilganda «o'zlashtirildi» belgisini oladi. Xato qilingan savol
/// qaytib, oxiri to'g'ri yechilsa ham — o'sha urinish o'zlashtirish
/// hisoblanmaydi, testni boshidan toza o'tish kerak. Shunday qilmasak,
/// «to'g'ri javobni ko'rib, ikkinchi marta bosish» ham o'tkazib
/// yuborardi va belgining ma'nosi qolmasdi.
class NahvQuiz extends StatefulWidget {
  final NahvLesson lesson;
  const NahvQuiz({super.key, required this.lesson});

  @override
  State<NahvQuiz> createState() => _NahvQuizState();
}

/// Savol turi: 0 — arabcha → ma'no, 1 — ma'no → arabcha, 2 — eshitib → ma'no.
class _NQ {
  final NahvPair pair;
  final int type;
  List<String> options;
  int correct;
  bool retried; // xatodan keyin qaytarilgan nusxami (XP bermaymiz)
  _NQ(this.pair, this.type, this.options, this.correct, {this.retried = false});
}

class _NahvQuizState extends State<NahvQuiz> {
  final _rnd = Random();
  final List<_NQ> _queue = [];
  int _total = 0; // birinchi urinishdagi savollar soni
  int _done = 0; // to'g'ri yechilgan NOYOB savollar (progress uchun)
  int _firstTry = 0; // birinchi urinishda to'g'ri
  int? _picked;
  bool _answered = false;

  String get _lessonId => 'nahv-${widget.lesson.book}-${widget.lesson.num}';

  @override
  void initState() {
    super.initState();
    _build();
  }

  /// Darsdan test tuzish. Juftliklar: qoida, xatboshilar, ro'yxat bandlari.
  ///
  /// Savollar darsning BUTUN matnidan tasodifiy olinadi — avval faqat eng
  /// qisqa 8 tasi olinardi, natijada uzun xatboshilar hech qachon
  /// so'ralmasdi va o'quvchi darsning yarmini ko'rmay «tugatgan» bo'lardi.
  ///
  /// Juda uzun matn 4 ta variant ichida o'qib bo'lmaydi, shuning uchun
  /// [_maxPromptLen] dan uzunlari chetga suriladi; agar qisqalari yetmasa,
  /// boricha olinadi (aks holda ba'zi darslarda test umuman chiqmasdi).
  /// Qoida — darsning o'zagi — imkon boricha doim so'raladi.
  static const int _maxPromptLen = 160;
  static const int _maxQuestions = 12;

  void _build() {
    final pairs = _collect(widget.lesson)
        .where((p) => p.ar.trim().isNotEmpty && p.uz.trim().isNotEmpty)
        .toList();
    var usable = pairs.where((p) => p.ar.length <= _maxPromptLen).toList();
    if (usable.length < 6) usable = pairs;

    // Har urinishda boshqacha tanlansin — shunda dars bir necha marta
    // takrorlanganda butun matn qamrab olinadi.
    final shuffled = List<NahvPair>.from(usable)..shuffle(_rnd);
    final rule = widget.lesson.rule;
    final picked = <NahvPair>[];
    if (rule.ar.trim().isNotEmpty &&
        rule.uz.trim().isNotEmpty &&
        usable.contains(rule)) {
      picked.add(rule);
    }
    for (final p in shuffled) {
      if (picked.length >= _maxQuestions) break;
      if (!picked.contains(p)) picked.add(p);
    }
    picked.shuffle(_rnd);

    // Chalg'ituvchi javoblar shu darsdan, yetmasa shu kitobning boshqa
    // darslaridan olinadi - mavzuga yaqin bo'lsin.
    final poolUz = <String>{for (final p in pairs) p.uz.trim()};
    final poolAr = <String>{for (final p in pairs) p.ar.trim()};
    for (final l in repo.nahvLessons.where((l) => l.book == widget.lesson.book)) {
      if (poolUz.length > 40) break;
      for (final p in _collect(l)) {
        if (p.uz.trim().isNotEmpty) poolUz.add(p.uz.trim());
        if (p.ar.trim().isNotEmpty) poolAr.add(p.ar.trim());
      }
    }

    for (final p in picked) {
      // Eshitish savoli faqat qisqa matnga beriladi - uzun xatboshini
      // eshitib ushlab qolish boshlovchi uchun og'ir.
      final types = p.ar.length <= 60 ? [0, 1, 2] : [0, 1];
      _queue.add(_make(p, types[_rnd.nextInt(types.length)], poolUz, poolAr));
    }
    _total = _queue.length;
  }

  List<NahvPair> _collect(NahvLesson l) {
    final out = <NahvPair>[];
    if (l.rule.ar.isNotEmpty) out.add(l.rule);
    for (final b in l.blocks) {
      if (b.main != null) out.add(b.main!);
      if (b.intro != null) out.add(b.intro!);
      out.addAll(b.items);
    }
    return out;
  }

  _NQ _make(NahvPair p, int type, Set<String> poolUz, Set<String> poolAr,
      {bool retried = false}) {
    final bool wantAr = type == 1;
    final answer = wantAr ? p.ar.trim() : p.uz.trim();
    final pool = (wantAr ? poolAr : poolUz).where((x) => x != answer).toList()
      ..shuffle(_rnd);
    final options = [answer, ...pool.take(3)]..shuffle(_rnd);
    return _NQ(p, type, options, options.indexOf(answer), retried: retried);
  }

  _NQ get _q => _queue.first;

  void _speak() => Tts.instance.speak(_q.pair.ar, id: 'nquiz');

  void _choose(int i) {
    if (_answered) return;
    final ok = i == _q.correct;
    setState(() {
      _picked = i;
      _answered = true;
    });
    // Javobdan keyin to'g'ri talaffuz doim eshittiriladi.
    _speak();
    if (ok) {
      _done++;
      if (!_q.retried) _firstTry++;
    } else {
      // Xato savol yo'qolmaydi: navbat oxiriga qaytadi. Variantlari
      // qaytadan aralashtiriladi - o'quvchi javobning JOYINI emas,
      // O'ZINI yodlasin.
      final answer = _q.options[_q.correct];
      final options = List.of(_q.options)..shuffle(_rnd);
      _queue.add(_NQ(_q.pair, _q.type, options, options.indexOf(answer),
          retried: true));
    }
    Future.delayed(Duration(milliseconds: ok ? 900 : 1900), () {
      if (!mounted) return;
      setState(() {
        _queue.removeAt(0);
        _picked = null;
        _answered = false;
      });
      if (_queue.isEmpty) _finish();
    });
  }

  Future<void> _finish() async {
    final earned = _firstTry * 5;
    await progress.addXp(earned);
    // Dars faqat xatosiz o'tilganda o'zlashtirilgan hisoblanadi.
    final mastered = await progress.recordAttempt(_lessonId, _firstTry, _total);
    if (!mounted) return;
    final best = progress.bestPercent(_lessonId);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Text(mastered ? '⭐⭐⭐' : '💪', style: const TextStyle(fontSize: 34)),
            const SizedBox(height: 6),
            Text(mastered ? 'Dars o\'zlashtirildi!' : 'Yaqin qoldi',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Birinchi urinishda: $_firstTry / $_total\n+$earned XP',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            if (!mastered) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Dars «o\'zlashtirildi» belgisini olishi uchun testni '
                      'bitta ham xatosiz o\'tish kerak.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text('Eng yaxshi natijangiz: $best%',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              if (mastered) {
                _restart();
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(mastered ? 'Yana bir marta' : 'Keyinroq'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (mastered) {
                Navigator.pop(context);
              } else {
                _restart();
              }
            },
            child: Text(mastered ? 'Tayyor' : 'Qaytadan'),
          ),
        ],
      ),
    );
  }

  /// Testni boshidan qurish — savollar qaytadan tanlanadi, shuning uchun
  /// o'quvchi javoblarning JOYINI emas, o'zini yodlaydi.
  void _restart() {
    setState(() {
      _queue.clear();
      _done = 0;
      _firstTry = 0;
      _total = 0;
      _picked = null;
      _answered = false;
      _build();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return const Scaffold(body: SizedBox());
    }
    final q = _q;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lesson.num}-dars — test'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: _done / _total,
            minHeight: 6,
            backgroundColor: AppColors.softGreen,
            valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              switch (q.type) {
                0 => "Bu jumlaning ma'nosi qaysi?",
                1 => 'Arabchasi qaysi?',
                _ => "Tinglang — ma'nosi qaysi?",
              },
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 14),
            _prompt(q),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                children: [
                  for (var i = 0; i < q.options.length; i++) _option(q, i),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: Center(child: _feedback()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prompt(_NQ q) {
    final Widget inner;
    if (q.type == 1) {
      inner = Text(q.pair.uz,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.4));
    } else if (q.type == 2) {
      inner = IconButton(
        iconSize: 56,
        color: AppColors.emerald,
        icon: const Icon(Icons.volume_up_rounded),
        onPressed: _speak,
      );
    } else {
      inner = Directionality(
        textDirection: TextDirection.rtl,
        child: Text(q.pair.ar,
            textAlign: TextAlign.center,
            style: AppTheme.arabic(size: 24, color: AppColors.emerald)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: inner),
          if (q.type == 0)
            IconButton(
              onPressed: _speak,
              icon: const Icon(Icons.volume_up_rounded, color: AppColors.emerald),
            ),
        ],
      ),
    );
  }

  Widget _option(_NQ q, int i) {
    Color bg = Colors.white;
    Color border = Colors.black12;
    if (_answered) {
      if (i == q.correct) {
        bg = AppColors.success.withValues(alpha: 0.12);
        border = AppColors.success;
      } else if (i == _picked) {
        bg = AppColors.coral.withValues(alpha: 0.12);
        border = AppColors.coral;
      }
    }
    final arabic = q.type == 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _choose(i),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.6),
            ),
            child: arabic
                ? Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(q.options[i],
                        style: AppTheme.arabic(size: 19, color: AppColors.ink)))
                : Text(q.options[i],
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600,
                        color: AppColors.ink, height: 1.35)),
          ),
        ),
      ),
    );
  }

  Widget _feedback() {
    if (!_answered) return const SizedBox();
    final ok = _picked == _q.correct;
    return Text(
      ok ? "✅ To'g'ri!" : '🔁 Bu savol yana qaytadi — yodlab oling',
      style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: ok ? AppColors.success : AppColors.gold),
    );
  }
}
