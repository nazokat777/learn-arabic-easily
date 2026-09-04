import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import '../theme.dart';
import '../services/tts.dart';

/// Bitta test savoli.
class Question {
  final Widget prompt; // savol (arabcha harf/so'z yoki matn)
  final String promptLabel; // savol ustidagi ko'rsatma
  final List<String> options; // javob variantlari (matn)
  final int correct; // to'g'ri javob indeksi
  final String? speak; // ixtiyoriy: audio uchun arabcha matn

  /// Ovoz javobni oshkor qiladimi.
  ///
  /// Harflar testida variantlar harf NOMLARI, ovoz esa aynan o'sha nom —
  /// uni javobdan oldin eshittirish testni ma'nosiz qiladi. Bunday savolda
  /// tinglash tugmasi faqat javobdan keyin ko'rinadi (talaffuzni o'rganish
  /// uchun baribir foydali).
  final bool speakRevealsAnswer;

  Question({
    required this.prompt,
    required this.promptLabel,
    required this.options,
    required this.correct,
    this.speak,
    this.speakRevealsAnswer = false,
  });
}

/// Navbatdagi bitta savol.
///
/// [retried] — bu savol xatodan keyin qaytarilganmi. Qaytarilgan savol
/// to'g'ri yechilsa ham «birinchi urinishda to'g'ri» hisobiga kirmaydi,
/// aks holda «xato qil, javobni ko'r, keyin bos» ham o'zlashtirish
/// sanalardi.
class _QItem {
  final Question q;
  final bool retried;
  _QItem(this.q, this.retried);
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
  final _rnd = Random();

  /// Yechilmagan savollar navbati. Xato qilingan savol o'chmaydi — navbat
  /// OXIRIGA qaytadi, shuning uchun test hamma savol to'g'ri yechilmaguncha
  /// tugamaydi. Ilgari savollar bir marta berilib, 60% bilan «tugatildi»
  /// deb belgilanardi; o'quvchi harflarning yarmini bilmay o'tib ketardi.
  final List<_QItem> _queue = [];

  int _total = 0; // noyob savollar soni
  int _done = 0; // to'g'ri yechilgan noyob savollar
  int _firstTry = 0; // birinchi urinishdayoq to'g'ri yechilganlari
  int? _selected;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _queue
      ..clear()
      ..addAll(widget.questions.map((q) => _QItem(q, false)));
    _total = _queue.length;
    _done = 0;
    _firstTry = 0;
    _selected = null;
    _answered = false;
  }

  Question get _q => _queue.first.q;

  /// Xato savolni qaytarishdan oldin variantlar aralashtiriladi — aks holda
  /// o'quvchi javobning JOYINI yodlaydi, o'zini emas.
  Question _reshuffle(Question q) {
    final answer = q.options[q.correct];
    final opts = List<String>.from(q.options)..shuffle(_rnd);
    return Question(
      prompt: q.prompt,
      promptLabel: q.promptLabel,
      options: opts,
      correct: opts.indexOf(answer),
      speak: q.speak,
      speakRevealsAnswer: q.speakRevealsAnswer,
    );
  }

  void _requeue() {
    final cur = _queue.first;
    _queue.add(_QItem(_reshuffle(cur.q), true));
  }

  void _choose(int i) {
    if (_answered) return;
    final correct = i == _q.correct;
    setState(() {
      _selected = i;
      _answered = true;
    });
    if (correct) {
      _done++;
      if (!_queue.first.retried) _firstTry++;
    } else {
      _requeue();
    }
    // To'g'ri talaffuzni eshittiramiz.
    if (_q.speak != null) Tts.instance.speak(_q.speak!, id: 'q');
    Future.delayed(Duration(milliseconds: correct ? 700 : 1500), () {
      if (mounted && _answered) _next();
    });
  }

  /// «Bilmadim» — bilmagan odamni jazolamaymiz, balki O'RGATAMIZ:
  /// to'g'ri javobni ko'rsatamiz, audio o'qiymiz, keyin sekinroq o'tamiz.
  /// Savol baribir navbatga qaytadi: ko'rsatib berish o'rganish emas.
  void _dontKnow() {
    if (_answered) return;
    setState(() {
      _selected = null; // hech bir variant xato deb belgilanmaydi
      _answered = true;
    });
    _requeue();
    if (_q.speak != null) Tts.instance.speak(_q.speak!, id: 'q');
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted && _answered) _next();
    });
  }

  void _next() {
    setState(() {
      _queue.removeAt(0);
      _selected = null;
      _answered = false;
    });
    if (_queue.isEmpty) _finish();
  }

  Future<void> _finish() async {
    final earned = _firstTry * widget.xpPerCorrect;
    await progress.addXp(earned);
    // Dars faqat test BITTA HAM xatosiz o'tilganda o'zlashtirilgan bo'ladi.
    final mastered =
        await progress.recordAttempt(widget.lessonId, _firstTry, _total);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        firstTry: _firstTry,
        total: _total,
        earned: earned,
        mastered: mastered,
        best: progress.bestPercent(widget.lessonId),
        onAgain: () {
          Navigator.pop(context);
          setState(_reset);
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
    if (_queue.isEmpty) return const Scaffold(body: SizedBox());
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: _total == 0 ? 0 : _done / _total,
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
            Text('$_done / $_total',
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
            if (_q.speak != null && (!_q.speakRevealsAnswer || _answered)) ...[
              const SizedBox(height: 10),
              _ListenButton(text: _q.speak!),
            ],
            const SizedBox(height: 20),
            ...List.generate(_q.options.length, (i) => _option(i)),
            const Spacer(),
            // Javobdan oldin — «Bilmadim»; javobdan keyin — qisqa fikr.
            SizedBox(
              height: 48,
              child: _answered ? _feedback() : _dontKnowButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dontKnowButton() => OutlinedButton.icon(
        onPressed: _dontKnow,
        icon: const Text('🤔', style: TextStyle(fontSize: 18)),
        label: const Text('Bilmadim — javobni ko\'rsat',
            style: TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

  Widget _feedback() {
    if (_selected == null) {
      return const Text('📖 Mana to\'g\'ri javob — yodlab oling',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.gold));
    }
    final ok = _selected == _q.correct;
    return Text(ok ? '✅ To\'g\'ri!' : '❌ To\'g\'ri javob belgilandi',
        style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 16, color: ok ? AppColors.success : AppColors.coral));
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

/// Kichik «Eshitish» tugmasi — arabcha so'zni ovoz bilan o'qiydi.
class _ListenButton extends StatelessWidget {
  final String text;
  const _ListenButton({required this.text});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: Tts.instance.speakingId,
      builder: (context, s, _) {
        final on = s == text || s == 'q';
        return TextButton.icon(
          onPressed: () => Tts.instance.speak(text, id: text),
          icon: Icon(on ? Icons.volume_up_rounded : Icons.volume_up_outlined, color: AppColors.emerald),
          label: const Text('Eshitish', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700)),
        );
      },
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final int firstTry, total, earned, best;
  final bool mastered;
  final VoidCallback onAgain, onDone;
  const _ResultDialog({
    required this.firstTry,
    required this.total,
    required this.earned,
    required this.mastered,
    required this.best,
    required this.onAgain,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mastered ? '🏆' : '💪', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(mastered ? "Mukammal — o'zlashtirildi!" : 'Yaqin qoldi',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 12),
            Text("Birinchi urinishda: $firstTry / $total",
                style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('+$earned XP',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 16)),
            ),
            if (!mastered) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      "«O'zlashtirildi» belgisi uchun testni bitta ham "
                      "xatosiz o'tish kerak.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, height: 1.35),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: mastered ? onDone : onAgain,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.emerald),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(mastered ? 'Chiqish' : 'Keyinroq',
                        style: const TextStyle(
                            color: AppColors.emerald, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: mastered ? onDone : onAgain,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(mastered ? 'Tayyor' : 'Qaytadan',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
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
