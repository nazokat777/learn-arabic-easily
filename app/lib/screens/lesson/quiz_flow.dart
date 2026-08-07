import 'dart:math';
import 'package:flutter/material.dart';
import '../../arabic.dart';
import '../../content.dart';
import '../../main.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import 'vocab_flow.dart' show AwardXp;
import 'word_sheet.dart';

/// Savollar bosqichi — dars lug'ati bo'yicha test (har so'zdan bitta savol).
/// Xato javob berilgan so'zlar «xatolar» ro'yxatiga tushadi (keyin ko'riladi).
class QuizStage extends StatefulWidget {
  final QiroatLesson lesson;
  final void Function(List<QiroatVocab> missed) onFinish;
  final AwardXp award;
  const QuizStage({super.key, required this.lesson, required this.onFinish, required this.award});

  @override
  State<QuizStage> createState() => _QuizStageState();
}

class _QQ {
  final QiroatVocab word;
  final bool arToUz;
  final List<String> options;
  final int correct;
  _QQ(this.word, this.arToUz, this.options, this.correct);
}

class _QuizStageState extends State<QuizStage> {
  final _rnd = Random();
  late List<QiroatVocab> _pool;
  late List<_QQ> _questions;
  final List<QiroatVocab> _missed = [];
  int _qi = 0;
  int? _picked;
  bool _answered = false;

  String _key(QiroatVocab v) => '${widget.lesson.completionId}::${v.ar}';

  @override
  void initState() {
    super.initState();
    final seen = <String>{};
    _pool = [];
    for (final v in widget.lesson.vocab) {
      if (v.ar.trim().isEmpty || v.uz.trim().isEmpty) continue;
      if (seen.add(v.uz)) _pool.add(v);
    }
    _questions = _pool.map(_build).toList()..shuffle(_rnd);
    if (_questions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFinish(const []));
    }
  }

  _QQ _build(QiroatVocab word) {
    final head = splitForms(word.ar).first;
    final canReverse = !word.ar.contains('،') && stripDiacritics(head).length <= 12;
    final arToUz = !canReverse || _rnd.nextBool();
    final correctVal = arToUz ? word.uz : head;
    final distract = _pool
        .where((v) => v != word)
        .map((v) => arToUz ? v.uz : splitForms(v.ar).first)
        .where((s) => s != correctVal)
        .toSet()
        .toList()
      ..shuffle(_rnd);
    final options = <String>[correctVal, ...distract.take(3)]..shuffle(_rnd);
    return _QQ(word, arToUz, options, options.indexOf(correctVal));
  }

  Future<void> _answer(int i) async {
    if (_answered) return;
    final q = _questions[_qi];
    final ok = i == q.correct;
    setState(() {
      _picked = i;
      _answered = true;
    });
    if (ok) {
      widget.award(2);
    } else if (!_missed.contains(q.word)) {
      _missed.add(q.word);
    }
    await progress.bumpWord(_key(q.word), ok);
    Future.delayed(Duration(milliseconds: ok ? 650 : 1300), () {
      if (!mounted) return;
      if (_qi + 1 < _questions.length) {
        setState(() {
          _qi++;
          _picked = null;
          _answered = false;
        });
      } else {
        widget.onFinish(_missed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return const SizedBox.shrink();
    final q = _questions[_qi];
    final head = splitForms(q.word.ar).first;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: Row(
            children: [
              const Text('❓  Savollar',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15)),
              const Spacer(),
              Text('${_qi + 1} / ${_questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.emerald)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_qi + (_answered ? 1 : 0)) / _questions.length,
              minHeight: 8,
              backgroundColor: AppColors.softGreen,
              valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
            ),
          ),
        ),
        const Spacer(),
        Text(q.arToUz ? 'Bu so\'z nima degani?' : 'Qaysi so\'z «${q.word.uz}» degani?',
            style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: q.arToUz
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(head,
                            textAlign: TextAlign.center,
                            style: AppTheme.arabic(size: 40, color: AppColors.emerald)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.emerald,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Tts.instance.speak(head, id: head),
                        child: const SizedBox(
                            width: 42, height: 42,
                            child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 22)),
                      ),
                    ),
                  ],
                )
              : Text(q.word.uz,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.emerald)),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(children: List.generate(q.options.length, (i) => _optTile(q, i))),
        ),
        _feedback(q),
      ],
    );
  }

  Widget _optTile(_QQ q, int i) {
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
                    child: Text(q.options[i], style: AppTheme.arabic(size: 24, color: AppColors.ink)))
                : Text(q.options[i],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
        ),
      ),
    );
  }

  Widget _feedback(_QQ q) {
    if (!_answered) return const SizedBox(height: 52);
    final ok = _picked == q.correct;
    return Container(
      width: double.infinity,
      height: 52,
      alignment: Alignment.centerLeft,
      color: (ok ? AppColors.success : AppColors.coral).withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(ok ? '✅ To\'g\'ri! +2 XP' : '❌ To\'g\'ri javob: ${q.options[q.correct]}',
          style: TextStyle(fontWeight: FontWeight.w800, color: ok ? AppColors.success : AppColors.coral)),
    );
  }
}

/// Xatolarni ko'rish bosqichi — testda xato qilingan so'zlarni qayta ko'rish.
class ReviewStage extends StatefulWidget {
  final QiroatLesson lesson;
  final List<QiroatVocab> missed;
  final VoidCallback onDone;
  const ReviewStage({super.key, required this.lesson, required this.missed, required this.onDone});

  @override
  State<ReviewStage> createState() => _ReviewStageState();
}

class _ReviewStageState extends State<ReviewStage> {
  int _i = 0;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.missed[_i];
    final head = splitForms(v.ar).first;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: Row(
            children: [
              const Text('🔁  Xatolar ustida ishlash',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15)),
              const Spacer(),
              Text('${_i + 1} / ${widget.missed.length}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.coral)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
            child: GestureDetector(
              onTap: () {
                if (!_revealed) {
                  setState(() => _revealed = true);
                  Tts.instance.speak(head, id: head);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(head,
                          textAlign: TextAlign.center,
                          style: AppTheme.arabic(size: 50, color: AppColors.emerald, w: FontWeight.w700)),
                    ),
                    const SizedBox(height: 16),
                    if (_revealed) ...[
                      Text(v.uz,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => showWordSheet(context, v, reading: widget.lesson.reading),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Batafsil'),
                      ),
                    ] else
                      const Text('Ma\'nosini eslang, keyin ochish uchun bosing',
                          style: TextStyle(color: Colors.black38)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (!_revealed) {
                  setState(() => _revealed = true);
                  return;
                }
                if (_i + 1 < widget.missed.length) {
                  setState(() {
                    _i++;
                    _revealed = false;
                  });
                } else {
                  widget.onDone();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(!_revealed
                  ? 'Ochish'
                  : (_i + 1 < widget.missed.length ? 'Keyingi' : 'Yakunlash'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}
