import '../../uz_yozuv.dart';
import 'package:flutter/material.dart' hide Text;
import '../../widgets/uz_text.dart';
import '../../arabic.dart';
import '../../content.dart';
import '../../main.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/ornament.dart';
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
  int _quizTotal =
      0; // oxirgi testdagi savollar soni (o'zlashtirishni hisoblash uchun)

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
        widget.lesson.completionId,
        _quizTotal - _missed.length,
        _quizTotal,
      );
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
            tooltip: uz('To\'liq dars (matn + lug\'at)'),
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QiroatLessonDetail(lesson: widget.lesson),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: XpChip(value: _sessionXp),
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

  /// Bosqichlar yo'li — nuqtalar oddiy chiziq bilan emas, OQIB TO'LADIGAN
  /// yo'l bilan bog'langan. O'quvchi qaysi bosqichda ekanini bir qarashda
  /// ko'radi; hozirgi bosqich nur bilan ajralib turadi.
  Widget _stepStrip() {
    const items = [
      (_Step.vocab, Icons.style_rounded, "Lug'at"),
      (_Step.listen, Icons.headphones_rounded, 'Tinglash'),
      (_Step.read, Icons.menu_book_rounded, "O'qish"),
      (_Step.quiz, Icons.quiz_rounded, 'Savol'),
    ];
    final order = [
      _Step.vocab,
      _Step.listen,
      _Step.read,
      _Step.quiz,
      _Step.review,
    ];
    final curIdx = order.indexOf(_step);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _node(
              items[i].$2,
              items[i].$3,
              done: order.indexOf(items[i].$1) < curIdx,
              current: order.indexOf(items[i].$1) == curIdx,
            ),
            if (i < items.length - 1)
              Expanded(
                child: Padding(
                  // 38 px doira markazi = 19; chiziq 4 px -> 17 dan boshlanadi.
                  padding: const EdgeInsets.fromLTRB(6, 17, 6, 0),
                  child: AnimatedBar(
                    value: order.indexOf(items[i + 1].$1) <= curIdx ? 1 : 0,
                    height: 4,
                    color: AppColors.emerald,
                    background: Colors.black12,
                    duration: const Duration(milliseconds: 650),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _node(
    IconData icon,
    String label, {
    required bool done,
    required bool current,
  }) {
    final active = done || current;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: kExpoOut,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done
                ? const LinearGradient(
                    colors: [AppColors.emerald, AppColors.emeraldDark],
                  )
                : null,
            color: done ? null : Colors.white,
            border: Border.all(
              color: active ? AppColors.emerald : Colors.black26,
              width: current ? 2.4 : 1.6,
            ),
            boxShadow: current
                ? [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            done ? Icons.check_rounded : icon,
            size: 19,
            color: done
                ? Colors.white
                : (current ? AppColors.emerald : Colors.black38),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: current ? FontWeight.w800 : FontWeight.w600,
            color: active ? AppColors.emeraldDark : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _stageBody() {
    final l = widget.lesson;
    switch (_step) {
      case _Step.intro:
        return _IntroView(
          lesson: l,
          onStart: () => setState(() => _step = _Step.vocab),
        );
      case _Step.vocab:
        return VocabStage(
          lesson: l,
          award: _award,
          onDone: () => setState(() => _step = _Step.listen),
        );
      case _Step.listen:
        return ListenStage(
          lesson: l,
          award: _award,
          onDone: () => setState(() => _step = _Step.read),
        );
      case _Step.read:
        return ReadStage(
          lesson: l,
          award: _award,
          onDone: () => setState(() => _step = _Step.quiz),
        );
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
          },
        );
      case _Step.review:
        return ReviewStage(lesson: l, missed: _missed, onDone: _goDone);
      case _Step.done:
        return _DoneView(lesson: l, xp: _sessionXp, onRetakeQuiz: _retakeQuiz);
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
    final words = lesson.vocab
        .where((v) => v.ar.trim().isNotEmpty && v.uz.trim().isNotEmpty)
        .length;
    final sentences = splitSentences(lesson.reading).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      children: [
        Center(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              lesson.titleAr,
              textAlign: TextAlign.center,
              style: AppTheme.arabic(
                size: 32,
                color: AppColors.emerald,
                w: FontWeight.w700,
              ),
            ),
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
                  Icon(
                    Icons.waving_hand_rounded,
                    color: AppColors.gold,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keling, bu darsni birga o\'rganamiz!',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _row(
                Icons.style_rounded,
                'Avval $words ta so\'zni kichik guruhlarda yodlaymiz',
              ),
              _row(
                Icons.headphones_rounded,
                'So\'ng $sentences ta jumlani tinglaymiz',
              ),
              _row(
                Icons.menu_book_rounded,
                'Keyin matnni o\'zimiz o\'qib tushunamiz',
              ),
              _row(
                Icons.quiz_rounded,
                'Oxirida savollarga javob beramiz va xatolarni ko\'ramiz',
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Boshlash',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QiroatLessonDetail(lesson: lesson),
              ),
            ),
            icon: const Icon(Icons.menu_book_rounded, size: 20),
            label: const Text(
              'To\'liq darsni ko\'rish (matn + lug\'at)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.emerald,
              side: const BorderSide(color: AppColors.emerald),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(IconData e, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(e, size: 18, color: AppColors.emerald),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            t,
            style: const TextStyle(color: AppColors.ink, height: 1.3),
          ),
        ),
      ],
    ),
  );
}

/// Tugash ekrani — darsning eng hissiy lahzasi.
///
/// Dizayn maqsadi: o'quvchi «men buni qildim» deb his qilsin. Shuning
/// uchun uch narsa birga ishlaydi: konfetti otilishi (faqat
/// o'zlashtirilganda — bayram loyiq bo'lsin), aylanuvchi nur halqasi
/// ichidagi kubok, va yugurib o'sadigan XP. Fonda xira girih naqshi.
///
/// Dars tugadi — lekin «o'zlashtirildi» degani emas. Ikkalasi ataylab
/// ajratib ko'rsatiladi, aks holda o'quvchi yarim bilim bilan oldinga
/// ketadi.
class _DoneView extends StatelessWidget {
  final QiroatLesson lesson;
  final int xp;
  final VoidCallback onRetakeQuiz;
  const _DoneView({
    required this.lesson,
    required this.xp,
    required this.onRetakeQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final mastered = progress.isMastered(lesson.completionId);
    final best = progress.bestPercent(lesson.completionId);
    return Stack(
      children: [
        const Positioned.fill(
          child: GirihPattern(
            color: AppColors.emerald,
            opacity: 0.035,
            cell: 76,
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 18, 26, 30),
          child: Column(
            children: [
              Reveal(
                duration: const Duration(milliseconds: 900),
                fromScale: 0.6,
                child: GlowRing(
                  size: 150,
                  color: mastered ? AppColors.gold : AppColors.emerald,
                  child: Float(
                    amplitude: 4,
                    child: Icon(
                      mastered
                          ? Icons.emoji_events_rounded
                          : Icons.flag_circle_rounded,
                      size: 74,
                      color: mastered ? AppColors.gold : AppColors.emerald,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Reveal(
                delay: const Duration(milliseconds: 180),
                child: Text(
                  mastered ? 'Barakalla!' : 'Yaqin qoldi',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: mastered ? AppColors.emerald : AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Reveal(
                delay: const Duration(milliseconds: 260),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    lesson.titleAr,
                    textAlign: TextAlign.center,
                    style: AppTheme.arabic(
                      size: 24,
                      color: AppColors.ink,
                      w: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Reveal(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  mastered
                      ? "Dars to'liq o'zlashtirildi"
                      : 'Dars tugadi — endi uni mustahkamlang',
                  style: const TextStyle(color: Colors.black54, fontSize: 13.5),
                ),
              ),
              const SizedBox(height: 18),
              const Reveal(
                delay: Duration(milliseconds: 360),
                child: OrnamentDivider(),
              ),
              const SizedBox(height: 18),
              Reveal(
                delay: const Duration(milliseconds: 420),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.goldLight, AppColors.gold],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppColors.deep),
                      const SizedBox(width: 6),
                      CountUp(
                        value: xp,
                        suffix: ' ball',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.deep,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!mastered) ...[
                const SizedBox(height: 16),
                Reveal(
                  delay: const Duration(milliseconds: 480),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
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
                        Text(
                          'Eng yaxshi natijangiz: $best%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Reveal(
                delay: const Duration(milliseconds: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!mastered) ...[
                      Tactile(
                        child: FilledButton.icon(
                          onPressed: onRetakeQuiz,
                          icon: const Icon(Icons.replay_rounded, size: 20),
                          label: const Text(
                            'Testni qaytadan topshirish',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Tactile(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MasterDrill(lesson: lesson),
                          ),
                        ),
                        icon: const Icon(Icons.psychology_alt, size: 20),
                        label: const Text(
                          "So'zlarni chuqur yodlash (6 usul)",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          side: const BorderSide(color: AppColors.gold),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Tactile(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Darslar ro'yxatiga qaytish",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
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
        // Konfetti eng ustida — faqat o'zlashtirilganda; bayram loyiq bo'lsin.
        if (mastered) const Positioned.fill(child: Confetti()),
      ],
    );
  }
}
