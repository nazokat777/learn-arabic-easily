import 'package:flutter/material.dart';
import '../main.dart';
import '../theme.dart';

/// Bitta test savoli.
class Question {
  final Widget prompt; // savol (arabcha harf/so'z yoki matn)
  final String promptLabel; // savol ustidagi ko'rsatma
  final List<String> options; // javob variantlari (matn)
  final int correct; // to'g'ri javob indeksi
  Question({required this.prompt, required this.promptLabel, required this.options, required this.correct});
}

/// Ko'p variantli interaktiv test — feedback, XP va yakuniy natija bilan.
class MultipleChoiceQuiz extends StatefulWidget {
  final String title;
  final String lessonId;
  final List<Question> questions;
  final int xpPerCorrect;
  const MultipleChoiceQuiz({
    super.key,
    required this.title,
    required this.lessonId,
    required this.questions,
    this.xpPerCorrect = 5,
  });

  @override
  State<MultipleChoiceQuiz> createState() => _MultipleChoiceQuizState();
}

class _MultipleChoiceQuizState extends State<MultipleChoiceQuiz> {
  int _index = 0;
  int _correctCount = 0;
  int? _selected;
  bool _answered = false;

  Question get _q => widget.questions[_index];

  void _choose(int i) {
    if (_answered) return;
    final correct = i == _q.correct;
    setState(() {
      _selected = i;
      _answered = true;
      if (correct) _correctCount++;
    });
    // Avtomatik keyingi savolga o'tish — tugma bosish shart emas.
    Future.delayed(Duration(milliseconds: correct ? 650 : 1300), () {
      if (mounted && _answered) _next();
    });
  }

  void _next() {
    if (_index < widget.questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final earned = _correctCount * widget.xpPerCorrect;
    await progress.addXp(earned);
    if (_correctCount >= (widget.questions.length * 0.6).ceil()) {
      await progress.markCompleted(widget.lessonId);
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        correct: _correctCount,
        total: widget.questions.length,
        earned: earned,
        onAgain: () {
          Navigator.pop(context);
          setState(() {
            _index = 0;
            _correctCount = 0;
            _selected = null;
            _answered = false;
          });
        },
        onDone: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_index + 1) / widget.questions.length,
            minHeight: 6,
            backgroundColor: AppColors.softGreen,
            valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('${_index + 1} / ${widget.questions.length}',
                style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text(_q.promptLabel, style: const TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: _q.prompt),
            ),
            const SizedBox(height: 24),
            ...List.generate(_q.options.length, (i) => _option(i)),
            const Spacer(),
            // Tugmasiz — javobdan so'ng qisqa fikr, keyin avtomatik keyingi savol.
            SizedBox(
              height: 32,
              child: _answered
                  ? Text(
                      _selected == _q.correct ? '✅ To\'g\'ri!' : '❌ To\'g\'ri javob belgilandi',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _selected == _q.correct ? AppColors.success : AppColors.coral),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(int i) {
    Color bg = Colors.white;
    Color border = Colors.black12;
    Widget? trailing;
    if (_answered) {
      if (i == _q.correct) {
        bg = AppColors.success.withValues(alpha: 0.12);
        border = AppColors.success;
        trailing = const Icon(Icons.check_circle, color: AppColors.success);
      } else if (i == _selected) {
        bg = AppColors.coral.withValues(alpha: 0.12);
        border = AppColors.coral;
        trailing = const Icon(Icons.cancel, color: AppColors.coral);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _choose(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(_q.options[i],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final int correct, total, earned;
  final VoidCallback onAgain, onDone;
  const _ResultDialog({
    required this.correct,
    required this.total,
    required this.earned,
    required this.onAgain,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final pct = correct / total;
    final emoji = pct >= 0.9 ? '🏆' : pct >= 0.6 ? '🎉' : '💪';
    final msg = pct >= 0.9
        ? 'Ajoyib! Mukammal natija!'
        : pct >= 0.6
            ? 'Barakalla! Yaxshi natija.'
            : 'Yaxshi harakat! Yana takrorlang.';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 12),
            Text('$correct / $total to\'g\'ri',
                style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('+$earned XP',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 16)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAgain,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.emerald),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Yana', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tayyor', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
