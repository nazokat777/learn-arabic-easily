import 'package:flutter/material.dart';
import '../../arabic.dart';
import '../../content.dart';
import '../../main.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import '../qiroat_lessons.dart' show QiroatLessonDetail;
import 'quiz_flow.dart';
import 'read_flow.dart';
import 'vocab_flow.dart';

/// Bitta darsni «shaxsiy muallim» kabi bosqichma-bosqich o'rgatuvchi oqim:
/// Kirish → Lug'at (5 tadan) → Tinglash → O'qish → Savollar → Xatolar → Tugatish.
/// Kitob mazmuni o'zgarmaydi — faqat o'rganish tajribasi.
class LessonFlow extends StatefulWidget {
  final QiroatLesson lesson;
  const LessonFlow({super.key, required this.lesson});

  @override
  State<LessonFlow> createState() => _LessonFlowState();
}

enum _Step { intro, vocab, listen, read, quiz, review, done }

class _LessonFlowState extends State<LessonFlow> {
  _Step _step = _Step.intro;
  int _sessionXp = 0;
  List<QiroatVocab> _missed = const [];

  void _award(int xp) {
    progress.addXp(xp); // fon rejimida saqlanadi
    setState(() => _sessionXp += xp);
  }

  @override
  void dispose() {
    Tts.instance.stop();
    super.dispose();
  }

  void _goDone() {
    if (!progress.isCompleted(widget.lesson.completionId)) {
      _award(15); // darsni tugatgani uchun bonus
      progress.markCompleted(widget.lesson.completionId);
    }
    setState(() => _step = _Step.done);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lesson.num}-dars'),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('⭐ $_sessionXp XP',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_step != _Step.intro && _step != _Step.done) _stepStrip(),
            Expanded(child: _stageBody()),
          ],
        ),
      ),
    );
  }

  Widget _stepStrip() {
    const items = [
      (_Step.vocab, Icons.style_rounded, 'Lug\'at'),
      (_Step.listen, Icons.headphones_rounded, 'Tinglash'),
      (_Step.read, Icons.menu_book_rounded, 'O\'qish'),
      (_Step.quiz, Icons.quiz_rounded, 'Savol'),
    ];
    final order = [_Step.vocab, _Step.listen, _Step.read, _Step.quiz, _Step.review];
    final curIdx = order.indexOf(_step);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _dot(items[i].$2, items[i].$3, order.indexOf(items[i].$1) <= curIdx,
                order.indexOf(items[i].$1) == curIdx),
            if (i < items.length - 1)
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: order.indexOf(items[i + 1].$1) <= curIdx
                      ? AppColors.emerald
                      : Colors.black12,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _dot(IconData icon, String label, bool active, bool current) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: active ? AppColors.emerald : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: active ? AppColors.emerald : Colors.black26, width: 2),
            boxShadow: current
                ? [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.4), blurRadius: 8)]
                : null,
          ),
          child: Icon(icon, size: 19, color: active ? Colors.white : Colors.black38),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: current ? FontWeight.w800 : FontWeight.w500,
                color: active ? AppColors.emeraldDark : Colors.black45)),
      ],
    );
  }

  Widget _stageBody() {
    final l = widget.lesson;
    switch (_step) {
      case _Step.intro:
        return _IntroView(lesson: l, onStart: () => setState(() => _step = _Step.vocab));
      case _Step.vocab:
        return VocabStage(
            lesson: l, award: _award, onDone: () => setState(() => _step = _Step.listen));
      case _Step.listen:
        return ListenStage(
            lesson: l, award: _award, onDone: () => setState(() => _step = _Step.read));
      case _Step.read:
        return ReadStage(
            lesson: l, award: _award, onDone: () => setState(() => _step = _Step.quiz));
      case _Step.quiz:
        return QuizStage(
            lesson: l,
            award: _award,
            onFinish: (missed) {
              _missed = missed;
              if (missed.isEmpty) {
                _goDone();
              } else {
                setState(() => _step = _Step.review);
              }
            });
      case _Step.review:
        return ReviewStage(lesson: l, missed: _missed, onDone: _goDone);
      case _Step.done:
        return _DoneView(lesson: l, xp: _sessionXp);
    }
  }
}

/// Kirish — darsga xush kelibsiz, qisqacha reja.
class _IntroView extends StatelessWidget {
  final QiroatLesson lesson;
  final VoidCallback onStart;
  const _IntroView({required this.lesson, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final words = lesson.vocab.where((v) => v.ar.trim().isNotEmpty && v.uz.trim().isNotEmpty).length;
    final sentences = splitSentences(lesson.reading).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      children: [
        Center(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(lesson.titleAr,
                textAlign: TextAlign.center,
                style: AppTheme.arabic(size: 32, color: AppColors.emerald, w: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.softGreen,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('👋', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Keling, bu darsni birga o\'rganamiz!',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _row('📚', 'Avval $words ta so\'zni kichik guruhlarda yodlaymiz'),
              _row('🎧', 'So\'ng $sentences ta jumlani tinglaymiz'),
              _row('📖', 'Keyin matnni o\'zimiz o\'qib tushunamiz'),
              _row('❓', 'Oxirida savollarga javob beramiz va xatolarni ko\'ramiz'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Boshlash', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => QiroatLessonDetail(lesson: lesson))),
            icon: const Icon(Icons.article_outlined, size: 18, color: Colors.black45),
            label: const Text('Kitob ko\'rinishi (matn + lug\'at)',
                style: TextStyle(color: Colors.black45)),
          ),
        ),
      ],
    );
  }

  Widget _row(String e, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: const TextStyle(color: AppColors.ink, height: 1.3))),
          ],
        ),
      );
}

/// Tugatish — tabrik animatsiyasi, XP, ijobiy fikr.
class _DoneView extends StatefulWidget {
  final QiroatLesson lesson;
  final int xp;
  const _DoneView({required this.lesson, required this.xp});

  @override
  State<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends State<_DoneView> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circle = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut));
    final text = CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.7, curve: Curves.easeOut));
    final emojis = ['🎉', '⭐', '🌟', '✨', '🏅'];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: circle,
              child: Container(
                width: 128, height: 128,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.emerald, AppColors.emeraldDark]),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 78),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(emojis.length, (i) {
                  final raw = ((_c.value - 0.4 - i * 0.06) / 0.5).clamp(0.0, 1.0);
                  final t = Curves.easeOut.transform(raw);
                  return Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(emojis[i], style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: text,
              child: Column(
                children: [
                  const Text('Barakalla! 🎊',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.emerald)),
                  const SizedBox(height: 8),
                  Text('«${widget.lesson.titleAr}» darsini tugatdingiz!',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: AppTheme.arabic(size: 20, color: AppColors.ink, w: FontWeight.w500)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text('+${widget.xp} XP',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Darslar ro\'yxatiga qaytish',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
