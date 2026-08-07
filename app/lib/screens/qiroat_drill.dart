import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import '../content.dart';
import '../progress.dart';
import '../theme.dart';

/// «So'zlarni yodlash» — Duolingo uslubidagi interaktiv mashq.
/// So'z YODLANGAN hisoblanishi uchun kamida [Progress.masteryGoal] (5) marta
/// to'g'ri javob berilishi kerak — bitta to'g'ri javob yetarli emas (tahmin
/// bilan o'tib ketmasin). Daraja saqlanadi (offline), sessiyalar aro to'planadi.
class QiroatVocabDrill extends StatefulWidget {
  final QiroatLesson lesson;
  const QiroatVocabDrill({super.key, required this.lesson});

  @override
  State<QiroatVocabDrill> createState() => _QiroatVocabDrillState();
}

class _Question {
  final QiroatVocab word;
  final bool arToUz;
  final List<String> options;
  final int correct;
  _Question(this.word, this.arToUz, this.options, this.correct);
}

class _QiroatVocabDrillState extends State<QiroatVocabDrill> {
  final _rnd = Random();
  late List<QiroatVocab> _pool; // takrorlanmas so'zlar (jami)
  late List<QiroatVocab> _queue; // shu sessiyada hali yodlanmagan so'zlar
  int _correctStreak = 0;
  int _xpEarned = 0;

  _Question? _q;
  int? _picked;
  bool _answered = false;

  String _key(QiroatVocab v) => '${widget.lesson.completionId}::${v.ar}';

  @override
  void initState() {
    super.initState();
    final seen = <String>{};
    _pool = [];
    for (final v in widget.lesson.vocab) {
      if (v.uz.trim().isEmpty || v.ar.trim().isEmpty) continue;
      if (seen.add(v.uz)) _pool.add(v);
    }
    _buildQueue();
    _next();
  }

  void _buildQueue() {
    _queue = _pool.where((v) => !progress.isWordLearned(_key(v))).toList()..shuffle(_rnd);
  }

  void _next() {
    if (_queue.isEmpty) {
      _q = null;
      return;
    }
    final word = _queue.first;
    final canReverse = !word.ar.contains('،') && word.ar.characters.length <= 10;
    final arToUz = !canReverse || _rnd.nextBool();
    final correctVal = arToUz ? word.uz : word.ar;
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

  Future<void> _answer(int i) async {
    if (_answered) return;
    final correct = i == _q!.correct;
    final word = _q!.word;
    setState(() {
      _picked = i;
      _answered = true;
      _correctStreak = correct ? _correctStreak + 1 : 0;
    });
    if (correct) {
      await progress.addXp(2);
      _xpEarned += 2;
    }
    final lvl = await progress.bumpWord(_key(word), correct);
    // Navbatni yangilaymiz: yodlanmagan so'z oxiriga qaytadi (qayta so'raladi).
    if (_queue.isNotEmpty) _queue.removeAt(0);
    if (!(correct && lvl >= Progress.masteryGoal)) _queue.add(word);
    if (mounted) setState(() {});
    Future.delayed(Duration(milliseconds: correct ? 650 : 1300), () {
      if (mounted && _answered) _advance();
    });
  }

  Future<void> _advance() async {
    if (_queue.isEmpty) {
      await progress.markCompleted('drill_${widget.lesson.completionId}');
      if (mounted) setState(() => _q = null);
    } else {
      setState(_next);
    }
  }

  int get _learned => _pool.where((v) => progress.isWordLearned(_key(v))).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.lesson.num}-dars — so\'zlarni yodlash')),
      body: SafeArea(child: _q == null ? _doneView() : _questionView()),
    );
  }

  Widget _doneView() {
    final allLearned = _learned >= _pool.length;
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
            Text(
              allLearned
                  ? 'Bu darsning barcha ${_pool.length} so\'zi yodlandi (har biri ${Progress.masteryGoal} marta)! +$_xpEarned XP'
                  : 'Zo\'r! +$_xpEarned XP. Yodlangan: $_learned / ${_pool.length} so\'z.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.ink, height: 1.4),
            ),
            const SizedBox(height: 28),
            if (!allLearned)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => setState(() {
                    _xpEarned = 0;
                    _correctStreak = 0;
                    _buildQueue();
                    _next();
                  }),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Davom etish',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            if (!allLearned) const SizedBox(height: 10),
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

  Widget _questionView() {
    final q = _q!;
    final total = _pool.length;
    final masterySum = _pool.fold<int>(0, (s, w) => s + progress.wordMastery(_key(w)));
    final value = total == 0 ? 0.0 : masterySum / (total * Progress.masteryGoal);
    final wordLvl = progress.wordMastery(_key(q.word));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: value,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Yodlangan: $_learned / $total so\'z',
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
              // Shu so'zning yodlash darajasi (nuqtalar): ●●●○○
              _masteryDots(wordLvl),
            ],
          ),
        ),
        const Spacer(),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(children: List.generate(q.options.length, (i) => _optionTile(q, i))),
        ),
        _feedbackBar(q),
      ],
    );
  }

  Widget _masteryDots(int lvl) {
    return Row(
      children: List.generate(Progress.masteryGoal, (i) {
        final on = i < lvl;
        return Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Icon(on ? Icons.circle : Icons.circle_outlined,
              size: 9, color: on ? AppColors.success : Colors.black26),
        );
      }),
    );
  }

  Widget _optionTile(_Question q, int i) {
    final isArabic = !q.arToUz;
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
                    child: Text(q.options[i], style: AppTheme.arabic(size: 24, color: AppColors.ink)),
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
              fontWeight: FontWeight.w800, color: ok ? AppColors.success : AppColors.coral)),
    );
  }
}
