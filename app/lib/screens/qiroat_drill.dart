import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import '../content.dart';
import '../theme.dart';

/// «So'zlarni yodlash» — Duolingo uslubidagi interaktiv mashq.
/// Darsning har bir so'zini to'g'ri javob berilgunicha qayta-qayta so'raydi.
class QiroatVocabDrill extends StatefulWidget {
  final QiroatLesson lesson;
  const QiroatVocabDrill({super.key, required this.lesson});

  @override
  State<QiroatVocabDrill> createState() => _QiroatVocabDrillState();
}

/// Bitta savol: arabcha so'z ko'rsatiladi, o'zbekcha ma'no tanlanadi;
/// yoki aksincha (o'zbekcha ko'rsatiladi, arabcha tanlanadi).
class _Question {
  final QiroatVocab word;
  final bool arToUz; // true: arabcha berilgan → o'zbekcha tanlanadi
  final List<String> options; // tanlov variantlari
  final int correct; // to'g'ri variant indeksi
  _Question(this.word, this.arToUz, this.options, this.correct);
}

class _QiroatVocabDrillState extends State<QiroatVocabDrill> {
  final _rnd = Random();
  late List<QiroatVocab> _pool; // takrorlanmas so'zlar
  late List<QiroatVocab> _queue; // hali yodlanmagan so'zlar (navbat)
  late int _total;
  int _mastered = 0;
  int _correctStreak = 0;
  int _xpEarned = 0;

  _Question? _q;
  int? _picked; // tanlangan variant
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    // uz bo'yicha takrorlanmas so'zlarni olamiz (chalg'ituvchi to'g'ri bo'lib qolmasin).
    final seen = <String>{};
    _pool = [];
    for (final v in widget.lesson.vocab) {
      if (v.uz.trim().isEmpty || v.ar.trim().isEmpty) continue;
      if (seen.add(v.uz)) _pool.add(v);
    }
    _queue = List<QiroatVocab>.from(_pool)..shuffle(_rnd);
    _total = _queue.length;
    _next();
  }

  void _next() {
    if (_queue.isEmpty) {
      _q = null;
      return;
    }
    final word = _queue.first;
    // Yo'nalish: qisqa (bir so'zli) arabcha bo'lsa gohida teskari ham so'raymiz.
    final canReverse = !word.ar.contains('،') && word.ar.characters.length <= 10;
    final arToUz = !canReverse || _rnd.nextBool();

    final correctVal = arToUz ? word.uz : word.ar;
    // Chalg'ituvchilar: bir xil yo'nalishdagi boshqa so'zlardan.
    final distractPool = _pool
        .where((v) => v != word)
        .map((v) => arToUz ? v.uz : v.ar)
        .where((s) => s != correctVal)
        .toSet()
        .toList()
      ..shuffle(_rnd);
    final options = <String>[correctVal, ...distractPool.take(3)]..shuffle(_rnd);
    _q = _Question(word, arToUz, options, options.indexOf(correctVal));
    _picked = null;
    _answered = false;
  }

  void _answer(int i) {
    if (_answered) return;
    final correct = i == _q!.correct;
    setState(() {
      _picked = i;
      _answered = true;
      if (correct) {
        _correctStreak++;
        _mastered++;
        _xpEarned += 2;
        _queue.removeAt(0); // yodlandi
      } else {
        _correctStreak = 0;
        // xato — so'zni navbat oxiriga qaytaramiz (qayta so'raladi)
        final w = _queue.removeAt(0);
        _queue.add(w);
      }
    });
    // Avtomatik keyingi savolga o'tish (tugma bosish shart emas).
    // To'g'ri javobda tez, xatoda biroz uzunroq (to'g'risini ko'rish uchun).
    Future.delayed(Duration(milliseconds: correct ? 650 : 1300), () {
      if (mounted && _answered) _continue();
    });
  }

  Future<void> _continue() async {
    if (_queue.isEmpty) {
      // tugadi — XP beramiz va belgilaymiz
      await progress.addXp(_xpEarned);
      await progress.markCompleted('drill_${widget.lesson.completionId}');
      if (mounted) setState(() => _q = null);
      return;
    }
    setState(() => _next());
  }

  @override
  Widget build(BuildContext context) {
    final done = _queue.isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.lesson.num}-dars — so\'zlarni yodlash')),
      body: SafeArea(
        child: done ? _doneView() : _questionView(),
      ),
    );
  }

  // --- Tugallash ekrani ---
  Widget _doneView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Barakalla!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.emerald)),
            const SizedBox(height: 8),
            Text('$_total ta so\'zni yodladingiz. +$_xpEarned XP',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.ink)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // qayta boshlash
                  setState(() {
                    _mastered = 0;
                    _correctStreak = 0;
                    _xpEarned = 0;
                    _queue = List<QiroatVocab>.from(_pool)..shuffle(_rnd);
                    _next();
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Yana mashq qilish',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: AppColors.emerald),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Darsga qaytish',
                    style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Savol ekrani ---
  Widget _questionView() {
    final q = _q!;
    final progressValue = _total == 0 ? 0.0 : _mastered / _total;
    return Column(
      children: [
        // Progress + streak
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 12,
                    backgroundColor: AppColors.softGreen,
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 2),
              Text('$_correctStreak',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.coral)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('$_mastered / $_total yodlandi',
                style: const TextStyle(fontSize: 12, color: Colors.black45)),
          ),
        ),
        const Spacer(),
        // Savol matni
        Text(q.arToUz ? 'Bu so\'z nima degani?' : 'Qaysi so\'z «${q.word.uz}» degani?',
            style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: q.arToUz
              ? Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(q.word.ar,
                      textAlign: TextAlign.center,
                      style: AppTheme.arabic(size: 40, color: AppColors.emerald)),
                )
              : Text(q.word.uz,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.emerald)),
        ),
        const Spacer(),
        // Variantlar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            children: List.generate(q.options.length, (i) => _optionTile(q, i)),
          ),
        ),
        // Feedback + davom
        _feedbackBar(q),
      ],
    );
  }

  Widget _optionTile(_Question q, int i) {
    final isArabic = !q.arToUz; // variantlar arabcha bo'lsa
    Color border = Colors.black12;
    Color bg = Colors.white;
    if (_answered) {
      if (i == q.correct) {
        border = AppColors.success;
        bg = AppColors.success.withValues(alpha: 0.10);
      } else if (i == _picked) {
        border = AppColors.coral;
        bg = AppColors.coral.withValues(alpha: 0.10);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _answered ? null : () => _answer(i),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.8),
            ),
            child: isArabic
                ? Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(q.options[i],
                        style: AppTheme.arabic(size: 24, color: AppColors.ink)),
                  )
                : Text(q.options[i],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
        ),
      ),
    );
  }

  Widget _feedbackBar(_Question q) {
    // Tugmasiz — faqat qisqa fikr-mulohaza; keyingi savolga avtomatik o'tadi.
    if (!_answered) return const SizedBox(height: 56);
    final ok = _picked == q.correct;
    return Container(
      width: double.infinity,
      height: 56,
      alignment: Alignment.centerLeft,
      color: (ok ? AppColors.success : AppColors.coral).withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(ok ? '✅ To\'g\'ri! +2 XP' : '❌ To\'g\'ri javob: ${q.options[q.correct]}',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ok ? AppColors.success : AppColors.coral)),
    );
  }
}
