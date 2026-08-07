import 'package:flutter/material.dart';
import '../main.dart';
import '../content.dart';
import '../theme.dart';

/// «Mabdaul qiroat» — darslar ro'yxati (1-kitob: Dars 1..N).
class QiroatLessonsList extends StatelessWidget {
  const QiroatLessonsList({super.key});

  @override
  Widget build(BuildContext context) {
    final lessons = repo.qiroatLessons;
    return Scaffold(
      appBar: AppBar(title: const Text('Mabdaul qiroat')),
      body: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _intro(),
            const SizedBox(height: 16),
            ...lessons.map((l) => _lessonTile(context, l)),
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
            const Expanded(
              child: Text(
                '«Mabdaul qiroa» (o\'qish asosi) — 1-kitob. Har bir darsda o\'qish matni va lug\'at bor.',
                style: TextStyle(color: AppColors.ink, height: 1.35),
              ),
            ),
          ],
        ),
      );

  Widget _lessonTile(BuildContext context, QiroatLesson l) {
    final done = progress.isCompleted('qiroat_${l.num}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => QiroatLessonDetail(lesson: l))),
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
            // O'qish matni — o'ngdan chapga, Amiri shrift
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Text(
                lesson.reading,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTheme.arabic(size: 26, color: AppColors.ink, w: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel('📚', 'Lug\'at (${lesson.vocab.length} so\'z)'),
            const SizedBox(height: 8),
            ...lesson.vocab.map(_vocabRow),
            const SizedBox(height: 24),
            _CompleteButton(lessonId: 'qiroat_${lesson.num}'),
          ],
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

  Widget _vocabRow(QiroatVocab v) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
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
