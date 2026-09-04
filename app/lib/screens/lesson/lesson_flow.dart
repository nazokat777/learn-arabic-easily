import 'package:flutter/material.dart';
import '../../arabic.dart';
import '../../content.dart';
import '../../main.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import '../qiroat_lessons.dart' show QiroatLessonDetail;
import 'master_drill.dart';
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
  int _quizTotal = 0; // oxirgi testdagi savollar soni (o'zlashtirishni hisoblash uchun)

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
    // Dars «o'zlashtirildi» belgisini faqat test BITTA HAM xatosiz
    // o'tilganda oladi. Xatolarni «Xatolar» bosqichida ko'rib chiqish
    // foydali, ammo o'zlashtirish o'rnini bosmaydi.
    if (_quizTotal > 0) {
      progress.recordAttempt(
          widget.lesson.completionId, _quizTotal - _missed.length, _quizTotal);
    }
    setState(() => _step = _Step.done);
  }

  /// Testni boshidan topshirish — o'zlashtira olmaganlar uchun.
  void _retakeQuiz() {
    setState(() {
      _missed = const [];
      _quizTotal = 0;
      _step = _Step.quiz;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lesson.num}-dars'),
        actions: [
          IconButton(
            tooltip: 'To\'liq dars (matn + lug\'at)',
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => QiroatLessonDetail(lesson: widget.lesson))),
          ),
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
            onFinish: (missed, total) {
              _missed = missed;
              _quizTotal = total;
              if (missed.isEmpty) {
                _goDone();
              } else {
                setState(() => _step = _Step.review);
              }
            });
      case _Step.review:
        return ReviewStage(lesson: l, missed: _missed, onDone: _goDone);
      case _Step.done:
        return _DoneView(
            lesson: l, xp: _sessionXp, onRetakeQuiz: _retakeQuiz);
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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => QiroatLessonDetail(lesson: lesson))),
            icon: const Icon(Icons.menu_book_rounded, size: 20),
            label: const Text('To\'liq darsni ko\'rish (matn + lug\'at)',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.emerald,
              side: const BorderSide(color: AppColors.emerald),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
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
  final VoidCallback onRetakeQuiz;
  const _DoneView(
      {required this.lesson, required this.xp, required this.onRetakeQuiz});

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
    // Dars tugadi — lekin «o'zlashtirildi» degani emas. Ikkalasini ajratib
    // ko'rsatamiz, aks holda o'quvchi yarim bilim bilan oldinga ketadi.
    final mastered = progress.isMastered(widget.lesson.completionId);
    final best = progress.bestPercent(widget.lesson.completionId);
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
                  Text(mastered ? 'Barakalla! 🎊' : 'Yaqin qoldi 💪',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: mastered ? AppColors.emerald : AppColors.gold)),
                  const SizedBox(height: 8),
                  Text('«${widget.lesson.titleAr}» darsini tugatdingiz!',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: AppTheme.arabic(size: 20, color: AppColors.ink, w: FontWeight.w500)),
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
                            "Dars «o'zlashtirildi» belgisini olishi uchun "
                            "testni bitta ham xatosiz o'tish kerak.",
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
            const SizedBox(height: 28),
            if (!mastered) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onRetakeQuiz,
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  label: const Text('Testni qaytadan topshirish',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MasterDrill(lesson: widget.lesson))),
                icon: const Icon(Icons.psychology_alt, size: 20),
                label: const Text('So\'zlarni chuqur yodlash (6 usul)',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
