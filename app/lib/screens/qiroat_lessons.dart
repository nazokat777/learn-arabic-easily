import '../uz_yozuv.dart';
import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';
import '../main.dart';
import '../mashq/bank.dart';
import '../mashq/mashq_ekran.dart';
import '../arabic.dart';
import '../content.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/entrance.dart';
import '../widgets/grammar_table.dart';
import '../widgets/mastery_badge.dart';
import '../widgets/premium_tile.dart';
import '../widgets/rasm_belgi.dart';
import '../widgets/speak_button.dart';
import 'qiroat_drill.dart';
import 'qiroat_match.dart';
import 'lesson/lesson_flow.dart';
import 'lesson/master_drill.dart';
import 'lesson/sentence_text.dart';

/// «Mabdaul qiroat» — kitob tanlash ekrani (1-kitob, 2-kitob, ...).
class QiroatBooksHome extends StatelessWidget {
  const QiroatBooksHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Mavjud kitoblarni aniqlaymiz (dars soni bilan).
    final books = <int, int>{}; // kitob -> darslar soni
    for (final l in repo.qiroatLessons) {
      books[l.book] = (books[l.book] ?? 0) + 1;
    }
    final bookNums = books.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Mabdaul qiroat')),
      body: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    'اِقْرَأْ',
                    style: AppTheme.arabic(size: 32, color: AppColors.emerald),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      '«Mabdaul qiroa» (o\'qish asosi). Kitobni tanlang.',
                      style: TextStyle(color: AppColors.ink, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...bookNums.asMap().entries.map(
              (e) => EntranceFade(
                delay: Duration(milliseconds: 60 + e.key * 80),
                child: _bookTile(context, e.value, books[e.value]!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookTile(BuildContext context, int book, int count) {
    // Kitobda O'ZLASHTIRILGAN darslar soni. Ataylab `isCompleted` emas:
    // ro'yxatdagi ✅ ham o'zlashtirishni bildiradi, ikkisi bir xil narsani
    // sanamasa raqam belgilar bilan zid chiqadi.
    final done = repo.qiroatLessons
        .where((l) => l.book == book && progress.isMastered(l.completionId))
        .length;
    return PremiumTile(
      title: '$book-kitob',
      subtitle: "$count dars · $done o'zlashtirildi",
      label: '$book',
      accent: AppColors.teal,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QiroatLessonsList(book: book)),
      ),
    );
  }
}

/// «Mabdaul qiroat» — bitta kitobning darslar ro'yxati (Dars 1..N).
class QiroatLessonsList extends StatelessWidget {
  final int book;
  const QiroatLessonsList({super.key, this.book = 1});

  @override
  Widget build(BuildContext context) {
    final lessons = repo.qiroatLessons.where((l) => l.book == book).toList();
    return Scaffold(
      appBar: AppBar(title: Text('$book-kitob')),
      body: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _intro(),
            const SizedBox(height: 16),
            ...lessons.asMap().entries.map(
              (e) => EntranceFade(
                // ilk ~12 karta ketma-ket, keyingilari birga (uzun quyruq bo'lmasin)
                delay: Duration(
                  milliseconds: 40 + (e.key < 12 ? e.key : 12) * 45,
                ),
                child: _lessonTile(context, e.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intro() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.softGreen,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Text(
          'اِقْرَأْ',
          style: AppTheme.arabic(size: 32, color: AppColors.emerald),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            '«Mabdaul qiroa» $book-kitob. Har bir darsda o\'qish matni va lug\'at bor.',
            style: const TextStyle(color: AppColors.ink, height: 1.35),
          ),
        ),
      ],
    ),
  );

  Widget _lessonTile(BuildContext context, QiroatLesson l) => PremiumTile(
    title: '${l.num}-dars',
    subtitle: "${MashqBank.qiroatDars(l).length} ta so'z",
    arabicSubtitle: l.titleAr,
    label: '${l.num}',
    accent: AppColors.teal,
    trailing: MasteryBadge(lessonId: l.completionId, size: 22),
    onTap: () {
      progress.oxirgiDarsniYoz(
        'qiroat',
        l.completionId,
        'Mabdaul qiroat · $book-kitob, ${l.num}-dars',
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LessonFlow(lesson: l)),
      );
    },
  );
}

/// Bitta darsning sahifasi: o'qish matni + lug'at jadvali.
class QiroatLessonDetail extends StatelessWidget {
  final QiroatLesson lesson;
  const QiroatLessonDetail({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${lesson.num}-dars')),
      body: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Sarlavha (arabcha)
            Center(
              child: Text(
                lesson.titleAr,
                textDirection: TextDirection.rtl,
                style: AppTheme.arabic(
                  size: 30,
                  color: AppColors.emerald,
                  w: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel(Icons.menu_book_rounded, 'O\'qish matni'),
            const SizedBox(height: 8),
            _ReadingBlock(lesson: lesson),
            if (lesson.translation.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FoldBlock(
                icon: Icons.translate_rounded,
                title: 'Tarjimasi',
                text: lesson.translation,
              ),
            ],
            if (lesson.exercise.isNotEmpty) ...[
              const SizedBox(height: 8),
              _FoldBlock(
                icon: Icons.edit_note_rounded,
                title: 'Mashq',
                text: lesson.exercise,
              ),
            ],
            if (lesson.exerciseAnswer.isNotEmpty) ...[
              const SizedBox(height: 8),
              _FoldBlock(
                icon: Icons.check_circle_rounded,
                title: 'Mashqning javobi',
                text: lesson.exerciseAnswer,
                arabic: true,
                vocab: lesson.vocab,
                reading: lesson.reading,
              ),
            ],
            const SizedBox(height: 24),
            _sectionLabel(
              Icons.style_rounded,
              'Lug\'at (${lesson.vocab.length} so\'z)',
            ),
            const SizedBox(height: 8),
            ...lesson.vocab.map(
              (v) => _VocabRow(v: v, reading: lesson.reading),
            ),
            for (final t in lesson.tables) ...[
              const SizedBox(height: 24),
              _sectionLabel(Icons.table_chart_rounded, t.title),
              const SizedBox(height: 8),
              GrammarTable(table: t),
            ],
            const SizedBox(height: 24),
            // Avval TEST (o'zlashtirish belgisi shundan), keyin mashq.
            // Qolgan o'yinlar yig'ilgan holda — asosiy yo'l ikkita tugma
            // bo'lsin, o'quvchi «qaysi birini bosay» deb turmasin.
            _CompleteButton(lesson: lesson),
            const SizedBox(height: 14),
            _BoshqaOyinlar(
              children: [
                _exerciseButton(
                  context,
                  color: AppColors.gold,
                  icon: Icons.psychology_alt,
                  label: "So'zlarni chuqur yodlash (6 usul)",
                  page: MasterDrill(lesson: lesson),
                ),
                const SizedBox(height: 10),
                _exerciseButton(
                  context,
                  color: AppColors.coral,
                  icon: Icons.bolt,
                  label: 'Tezkor mashq',
                  page: QiroatVocabDrill(lesson: lesson),
                ),
                const SizedBox(height: 10),
                _exerciseButton(
                  context,
                  color: AppColors.emerald,
                  icon: Icons.extension,
                  label: "Juftlash o'yini",
                  page: QiroatMatchGame(lesson: lesson),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseButton(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required Widget page,
  }) {
    return PressableScale(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.emerald),
      const SizedBox(width: 8),
      Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: AppColors.ink,
        ),
      ),
    ],
  );
}

/// O'qish matni: butun matnni ketma-ket tinglash tugmasi, har bir jumlada
/// alohida ovoz tugmasi, va har bir so'z bosiladigan (ma'nosi + talaffuzi).
class _ReadingBlock extends StatefulWidget {
  final QiroatLesson lesson;
  const _ReadingBlock({required this.lesson});

  @override
  State<_ReadingBlock> createState() => _ReadingBlockState();
}

class _ReadingBlockState extends State<_ReadingBlock> {
  late final List<String> _sentences = splitSentences(widget.lesson.reading);
  bool _playingAll = false;

  @override
  void dispose() {
    Tts.instance.stop();
    super.dispose();
  }

  Future<void> _playAll() async {
    if (_playingAll) {
      setState(() => _playingAll = false);
      await Tts.instance.stop();
      return;
    }
    setState(() => _playingAll = true);
    for (var i = 0; i < _sentences.length; i++) {
      if (!mounted || !_playingAll) break;
      await Tts.instance.speak(_sentences[i], id: 'all$i');
    }
    if (mounted) setState(() => _playingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _playAll,
              icon: Icon(
                _playingAll ? Icons.stop_circle : Icons.play_circle_fill,
                color: _playingAll ? AppColors.gold : AppColors.emerald,
              ),
              label: Text(
                _playingAll ? 'To\'xtatish' : 'Butun matnni tinglash',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          for (var i = 0; i < _sentences.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpeakButton(text: _sentences[i], id: 'sent$i', size: 18),
                  Expanded(
                    child: SentenceText(
                      sentence: _sentences[i],
                      vocab: widget.lesson.vocab,
                      reading: widget.lesson.reading,
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

/// Lug'at qatori — arabcha so'zni tinglash tugmasi bilan.
class _VocabRow extends StatelessWidget {
  final QiroatVocab v;

  /// Darsning o'qish matni — so'z ishlatilgan jumlani topish uchun.
  final String reading;
  const _VocabRow({required this.v, required this.reading});

  @override
  Widget build(BuildContext context) {
    // Fe'l shakllari «غَلِطَ، يَغْلَطُ...» bo'lsa, birinchi shaklni o'qiymiz.
    final head = splitForms(v.ar).isEmpty ? v.ar : splitForms(v.ar).first;
    // Yolg'iz so'zni TTS vaqf shaklida o'qiydi (oxirgi unli tushadi).
    // Jumla ichida esa to'liq eshitiladi - shuning uchun ikkinchi tugma.
    final misol = findSentenceFor(v.ar, reading);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(6, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SpeakButton(text: head, id: 'v${v.ar}', size: 19),
          RasmBelgi(uz: v.uz, olcham: 30),
          const SizedBox(width: 6),
          if (misol != null)
            SpeakButton(
              text: misol,
              id: 'vj${v.ar}',
              size: 17,
              icon: Icons.format_quote_rounded,
              tooltip: uz("Jumlada tinglash — so'z to'liq o'qiladi"),
            ),
          Expanded(
            child: Text(
              v.uz,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  v.ar,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTheme.arabic(size: 22, color: AppColors.emerald),
                ),
                if (v.pl.isNotEmpty)
                  Text(
                    'ko\'pligi: ${v.pl}',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: AppTheme.arabic(
                      size: 15,
                      color: AppColors.gold,
                      w: FontWeight.w500,
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

/// Dars ekranining pastidagi o'zlashtirish holati va testga o'tish tugmasi.
///
/// Ilgari bu yerda «Darsni tugatdim (+15 XP)» tugmasi turardi: o'quvchi
/// hech narsa tekshirilmasdan o'zini tugatdim deb belgilardi. Endi belgini
/// faqat test beradi — matnni ko'zdan kechirish bilimni isbotlamaydi.
class _CompleteButton extends StatelessWidget {
  final QiroatLesson lesson;
  const _CompleteButton({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MasteryCallToAction(
          lessonId: lesson.completionId,
          what: "lug'at va matn",
          onStart: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LessonFlow(lesson: lesson)),
          ),
        ),
        const SizedBox(height: 10),
        QiroatMashqTugmasi(lesson: lesson),
      ],
    );
  }
}

/// «Mustahkamlash» tugmasi: shu darsning lug'ati 100% bo'lguncha, so'ng
/// shu darsgacha bo'lgan hamma lug'at aralash, oxirida esa so'zlar
/// o'zbekchadan arabchaga harflab yoziladi.
class QiroatMashqTugmasi extends StatelessWidget {
  final QiroatLesson lesson;
  const QiroatMashqTugmasi({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MashqEkran(
            sarlavha: '${lesson.num}-dars mashqi',
            darsniki: MashqBank.qiroatDars(lesson),
            oldingilar: MashqBank.qiroatGacha(lesson),
            darsId: lesson.completionId,
            testgaOt: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LessonFlow(lesson: lesson)),
            ),
          ),
        ),
      ),
      icon: const Icon(Icons.fitness_center_rounded, size: 20),
      label: const Text(
        'Mashq qilish',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        side: const BorderSide(color: AppColors.gold),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

/// «Boshqa o'yinlar» — yig'ilgan qo'shimcha mashqlar.
///
/// Ular o'chirilmadi (foydali), lekin asosiy yo'ldan chetga olindi:
/// ekranda beshta rangli tugma turganda test qaysi biri ekani
/// bilinmay qolgan edi.
class _BoshqaOyinlar extends StatefulWidget {
  final List<Widget> children;
  const _BoshqaOyinlar({required this.children});

  @override
  State<_BoshqaOyinlar> createState() => _BoshqaOyinlarState();
}

class _BoshqaOyinlarState extends State<_BoshqaOyinlar> {
  bool _ochiq = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _ochiq = !_ochiq),
          icon: AnimatedRotation(
            turns: _ochiq ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.expand_more_rounded),
          ),
          label: const Text(
            "Boshqa o'yinlar",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: TextButton.styleFrom(foregroundColor: Colors.black54),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          crossFadeState: _ochiq
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.children,
          ),
        ),
      ],
    );
  }
}

/// Grammatika jadvali — kitobdagi katakli jadvalning ilovadagi ko'rinishi.
///
/// Telefon ekraniga oltita ustun sig'magani uchun har bir qator alohida karta
/// bo'lib chiqadi: arabcha katak + uning o'zbekcha ma'nosi. Shu bilan jadval
/// mazmuni to'liq saqlanadi va har bir arabcha shaklni tinglash mumkin.
class _FoldBlock extends StatefulWidget {
  final IconData icon;
  final String title;
  final String text;
  final bool arabic;

  /// Arabcha bo'limda so'z bosilganda izoh ko'rsatish uchun darsning
  /// lug'ati va matni kerak bo'ladi.
  final List<QiroatVocab> vocab;
  final String reading;
  const _FoldBlock({
    required this.icon,
    required this.title,
    required this.text,
    this.arabic = false,
    this.vocab = const [],
    this.reading = '',
  });
  @override
  State<_FoldBlock> createState() => _FoldBlockState();
}

class _FoldBlockState extends State<_FoldBlock> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18, color: AppColors.emerald),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.emerald,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: widget.arabic
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Javob ham o'qish matni kabi tinglanadi: har bir jumla
                        // alohida, so'zini bossa - o'sha so'z.
                        for (final s in splitSentences(widget.text))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SpeakButton(text: s, id: 'javob-$s', size: 18),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: SentenceText(
                                    sentence: s,
                                    vocab: widget.vocab,
                                    reading: widget.reading,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  : Text(
                      widget.text,
                      style: const TextStyle(
                        color: AppColors.ink,
                        height: 1.45,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
