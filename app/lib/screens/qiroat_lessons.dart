import 'package:flutter/material.dart';
import '../main.dart';
import '../arabic.dart';
import '../content.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/entrance.dart';
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
                  Text('اِقْرَأْ', style: AppTheme.arabic(size: 32, color: AppColors.emerald)),
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
            ...bookNums.asMap().entries.map((e) => EntranceFade(
                  delay: Duration(milliseconds: 60 + e.key * 80),
                  child: _bookTile(context, e.value, books[e.value]!),
                )),
          ],
        ),
      ),
    );
  }

  Widget _bookTile(BuildContext context, int book, int count) {
    // Kitobdagi tugatilgan darslar soni.
    final done = repo.qiroatLessons
        .where((l) => l.book == book && progress.isCompleted(l.completionId))
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => QiroatLessonsList(book: book))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.emerald, AppColors.emeraldDark]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text('$book',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$book-kitob',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      Text('$count dars · $done tugatildi',
                          style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.emerald),
              ],
            ),
          ),
        ),
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
            ...lessons.asMap().entries.map((e) => EntranceFade(
                  // ilk ~12 karta ketma-ket, keyingilari birga (uzun quyruq bo'lmasin)
                  delay: Duration(milliseconds: 40 + (e.key < 12 ? e.key : 12) * 45),
                  child: _lessonTile(context, e.value),
                )),
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
            Text('اِقْرَأْ', style: AppTheme.arabic(size: 32, color: AppColors.emerald)),
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

  Widget _lessonTile(BuildContext context, QiroatLesson l) {
    final done = progress.isCompleted(l.completionId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => LessonFlow(lesson: l))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.emerald, AppColors.emeraldDark]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text('${l.num}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l.num}-dars',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      Text(l.titleAr,
                          textDirection: TextDirection.rtl,
                          style: AppTheme.arabic(size: 18, color: AppColors.emerald)),
                    ],
                  ),
                ),
                if (done)
                  const Icon(Icons.check_circle, color: AppColors.success)
                else
                  const Icon(Icons.chevron_right, color: AppColors.emerald),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
              child: Text(lesson.titleAr,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabic(size: 30, color: AppColors.emerald, w: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            _sectionLabel('📖', 'O\'qish matni'),
            const SizedBox(height: 8),
            _ReadingBlock(lesson: lesson),
            const SizedBox(height: 24),
            _sectionLabel('📚', 'Lug\'at (${lesson.vocab.length} so\'z)'),
            const SizedBox(height: 8),
            ...lesson.vocab.map((v) => _VocabRow(v: v)),
            const SizedBox(height: 24),
            const Text('🎮 Mashqlar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
            const SizedBox(height: 10),
            // «So'zlarni chuqur yodlash» — 6 usulli master drill (har so'z 6 xil usulda)
            _exerciseButton(
              context,
              color: AppColors.gold,
              icon: Icons.psychology_alt,
              label: 'So\'zlarni chuqur yodlash (6 usul)',
              page: MasterDrill(lesson: lesson),
            ),
            const SizedBox(height: 10),
            // Oddiy tez mashq (ko'p variantli)
            _exerciseButton(
              context,
              color: AppColors.coral,
              icon: Icons.bolt,
              label: 'Tezkor mashq',
              page: QiroatVocabDrill(lesson: lesson),
            ),
            const SizedBox(height: 10),
            // «Juftlash o'yini» — arabcha↔o'zbekcha moslashtirish
            _exerciseButton(
              context,
              color: AppColors.emerald,
              icon: Icons.extension,
              label: 'Juftlash o\'yini',
              page: QiroatMatchGame(lesson: lesson),
            ),
            const SizedBox(height: 16),
            _CompleteButton(lessonId: lesson.completionId),
          ],
        ),
      ),
    );
  }

  Widget _exerciseButton(BuildContext context,
      {required Color color,
      required IconData icon,
      required String label,
      required Widget page}) {
    return PressableScale(
      child: Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _sectionLabel(String emoji, String text) => Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
        ],
      );

}

/// Kichik dumaloq ovoz tugmasi. O'qilayotganda belgisi «to'xtat»ga o'zgaradi,
/// shunda foydalanuvchi qaysi qator gapirayotganini ko'rib turadi.
class _SpeakButton extends StatelessWidget {
  final String text;
  final String id;
  final double size;
  const _SpeakButton({required this.text, required this.id, this.size = 20});

  @override
  Widget build(BuildContext context) {
    if (!Tts.instance.available) return const SizedBox.shrink();
    return ValueListenableBuilder<String?>(
      valueListenable: Tts.instance.speakingId,
      builder: (context, speaking, _) {
        final active = speaking == id;
        return IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: size + 16, height: size + 16),
          tooltip: active ? 'To\'xtatish' : 'Tinglash',
          icon: Icon(active ? Icons.stop_circle : Icons.volume_up_rounded,
              size: size, color: active ? AppColors.gold : AppColors.emerald),
          onPressed: () {
            if (active) {
              Tts.instance.stop();
              return;
            }
            if (Tts.instance.arabicAvailable.value == false) {
              showArabicVoiceHelp(context);
              return;
            }
            Tts.instance.speak(text, id: id);
          },
        );
      },
    );
  }
}

/// Qurilmada arabcha ovoz yo'q bo'lsa — jimgina o'tib ketmasdan, nima qilish
/// kerakligini tushuntiramiz. Aks holda foydalanuvchi tugmani bosaveradi va
/// nega ovoz chiqmayotganini bilmaydi.
void showArabicVoiceHelp(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Arabcha ovoz o\'rnatilmagan'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ilova telefoningizdagi ovoz tizimidan foydalanadi, '
                'lekin unda arabcha ovoz topilmadi.'),
            SizedBox(height: 14),
            Text('Android’da o‘rnatish:',
                style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('1. Sozlamalar → Til va kiritish\n'
                '2. Matndan nutqqa (Text-to-speech)\n'
                '3. Google matndan nutqqa → ⚙️ → Tillarni o‘rnatish\n'
                '4. «العربية / Arabic» ni yuklab oling\n'
                '5. Brauzerni butunlay yopib, qaytadan oching'),
            SizedBox(height: 14),
            Text('iPhone’da:', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Sozlamalar → Universal kirish → So‘zlangan kontent → '
                'Ovozlar → Arabcha'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tushunarli'),
        ),
      ],
    ),
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
    if (Tts.instance.arabicAvailable.value == false) {
      showArabicVoiceHelp(context);
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (Tts.instance.available)
            ValueListenableBuilder<bool?>(
              valueListenable: Tts.instance.arabicAvailable,
              builder: (context, hasArabic, _) => Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: _playAll,
                      icon: Icon(
                          _playingAll ? Icons.stop_circle : Icons.play_circle_fill,
                          color: _playingAll ? AppColors.gold : AppColors.emerald),
                      label: Text(
                          _playingAll ? 'To\'xtatish' : 'Butun matnni tinglash',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    // Arabcha ovoz yo'qligini oldindan aytamiz — tugmani
                    // bosib, jimlikdan hayron bo'lib qolmasin.
                    if (hasArabic == false)
                      IconButton(
                        tooltip: 'Arabcha ovoz o\'rnatilmagan',
                        icon: const Icon(Icons.info_outline,
                            color: AppColors.coral, size: 20),
                        onPressed: () => showArabicVoiceHelp(context),
                      ),
                  ],
                ),
              ),
            ),
          for (var i = 0; i < _sentences.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SpeakButton(text: _sentences[i], id: 'sent$i', size: 18),
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
  const _VocabRow({required this.v});

  @override
  Widget build(BuildContext context) {
    // Fe'l shakllari «غَلِطَ، يَغْلَطُ...» bo'lsa, birinchi shaklni o'qiymiz.
    final head = splitForms(v.ar).isEmpty ? v.ar : splitForms(v.ar).first;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(6, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _SpeakButton(text: head, id: 'v${v.ar}', size: 19),
          Expanded(
            child: Text(v.uz,
                style: const TextStyle(
                    color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 14.5)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(v.ar,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: AppTheme.arabic(size: 22, color: AppColors.emerald)),
                if (v.pl.isNotEmpty)
                  Text('ko\'pligi: ${v.pl}',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTheme.arabic(size: 15, color: AppColors.gold, w: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «Tugatdim» tugmasi — XP beradi va darsni tugatilgan deb belgilaydi.
class _CompleteButton extends StatelessWidget {
  final String lessonId;
  const _CompleteButton({required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final done = progress.isCompleted(lessonId);
    if (done) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('✅ Bu dars tugatildi',
            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800)),
      );
    }
    return FilledButton(
      onPressed: () async {
        await progress.addXp(15);
        await progress.markCompleted(lessonId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barakalla! +15 XP'), duration: Duration(seconds: 2)),
          );
        }
      },
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.emerald,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text('Darsni tugatdim  (+15 XP)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }
}
