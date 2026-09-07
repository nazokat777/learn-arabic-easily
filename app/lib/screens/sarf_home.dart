import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';

import '../content.dart';
import '../main.dart';
import '../mashq/bank.dart';
import '../mashq/mashq_ekran.dart';
import '../theme.dart';
import '../widgets/aralash_matn.dart';
import '../widgets/mastery_badge.dart';
import '../widgets/motion.dart';
import '../widgets/premium_tile.dart';
import '../widgets/speak_button.dart';

/// Sarf moduli — «Mukammal sarf darsligi» (Do'stmuhammad Nasriddin
/// Bodariy, Toshkent, 2009).
///
/// Nahv modulidan alohida ekran: o'sha kitobda har blok arabcha jumla va
/// uning tarjimasi edi, bu kitobda esa matn o'zbekcha yozilgan, arabcha
/// misollar gap ichida keladi (qarang: [AralashMatn]).
class SarfHome extends StatelessWidget {
  const SarfHome({super.key});

  @override
  Widget build(BuildContext context) {
    final darslar = repo.sarfLessons;
    return Scaffold(
      appBar: AppBar(title: const Text('Sarf')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: darslar.isEmpty
              ? const _BoshHolat()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    const Reveal(child: _Sarlavha()),
                    const SizedBox(height: 14),
                    for (var i = 0; i < darslar.length; i++)
                      Reveal(
                        delay: Duration(milliseconds: 40 * i),
                        child: _tile(context, darslar[i]),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, SarfLesson l) => PremiumTile(
    label: '${l.num}',
    title: l.title,
    // Kitobda sarlavhasi bo'lmagan darsda arabcha satr chizilmaydi.
    arabicSubtitle: l.titleAr.isEmpty ? null : l.titleAr,
    accent: AppColors.indigo,
    trailing: MasteryBadge(lessonId: l.completionId),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SarfLessonScreen(lesson: l)),
    ),
  );
}

class _Sarlavha extends StatelessWidget {
  const _Sarlavha();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'دروس الصرف الكامل',
              style: AppTheme.arabic(size: 26, color: AppColors.indigo),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mukammal sarf darsligi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 2),
          const Text(
            "Do'stmuhammad Nasriddin Bodariy — Toshkent, «Movarounnahr», 2009",
            style: TextStyle(color: Colors.black54, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _BoshHolat extends StatelessWidget {
  const _BoshHolat();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(28),
    child: Center(
      child: Text(
        'Sarf darslari hali yuklanmadi. Internetga ulanib, ilovani qayta '
        'oching — darslar saytdan olinadi.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54, height: 1.4),
      ),
    ),
  );
}

/// Bitta sarf darsi.
class SarfLessonScreen extends StatelessWidget {
  final SarfLesson lesson;
  const SarfLessonScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${lesson.num}-dars')),
      // Matn ustuni cheklanadi — keng ekranda satr cho'zilib ketmasin.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (lesson.titleAr.isNotEmpty)
                Center(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      lesson.titleAr,
                      textAlign: TextAlign.center,
                      style: AppTheme.arabic(
                        size: 26,
                        color: AppColors.indigo,
                        w: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Text(
                  lesson.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final b in lesson.blocks) ...[
                _blok(b),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              MasteryCallToAction(
                lessonId: lesson.completionId,
                what: 'atamalar va misollar',
                onStart: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MashqEkran(
                      sarlavha: '${lesson.num}-dars mashqi',
                      darsniki: MashqBank.sarfDars(lesson),
                      oldingilar: MashqBank.sarfGacha(lesson),
                      darsId: lesson.completionId,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blok(SarfBlock b) {
    switch (b.type) {
      case 'misol':
        return _Misol(block: b);
      case 'list':
        return _Royxat(block: b);
      case 'jadval':
        return _Jadval(block: b);
      case 'bolim':
        return _Bolim(matn: b.uz);
      default:
        return AralashMatn(b.uz);
    }
  }
}

/// Kitobdagi kichik, o'rtaga tekislangan bo'lim sarlavhasi
/// («Muzakkar siyg'alari» kabi). Dars sarlavhasi emas — dars ichidagi
/// ajratuvchi, shuning uchun kichikroq va sokinroq ko'rinadi.
class _Bolim extends StatelessWidget {
  final String matn;
  const _Bolim({required this.matn});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 2),
    child: Center(
      child: Text(
        matn,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15.5,
          color: AppColors.indigo,
        ),
      ),
    ),
  );
}

/// Alohida turgan arabcha satr — o'qib berish tugmasi bilan.
class _Misol extends StatelessWidget {
  final SarfBlock block;
  const _Misol({required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpeakButton(text: block.ar, id: 'sarf-${block.ar}', size: 18),
              const SizedBox(width: 6),
              Expanded(child: AralashMatn(block.ar, arabchaOlchami: 24)),
            ],
          ),
          if (block.uz.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                block.uz,
                style: const TextStyle(color: Colors.black54, height: 1.35),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kitobdagi «boblar jadvali».
///
/// Telefon ekraniga sakkizta ustun sig'maydi, shuning uchun jadval
/// gorizontal suriladi: kitobdagi tuzilma (qaysi bob qaysi turdagi
/// o'zakda qanday ko'rinishda keladi) aynan shu tartibda saqlanadi —
/// uni qatorlarga bo'lib yuborsa, taqqoslash imkoni yo'qoladi.
class _Jadval extends StatelessWidget {
  final SarfBlock block;
  const _Jadval({required this.block});

  static const double _bobEni = 62;
  static const double _katakEni = 132;

  @override
  Widget build(BuildContext context) {
    final ustunlar = block.ustunlar;
    final jamiEni = _bobEni + _katakEni * ustunlar.length;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: jamiEni,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sarlavhaQatori(ustunlar),
              for (final q in block.qatorlar)
                q.bolimmi ? _bolimQatori(q) : _qator(q, ustunlar.length),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sarlavhaQatori(List<SarfUstun> ustunlar) => Container(
    color: AppColors.indigo.withValues(alpha: 0.12),
    // IntrinsicHeight: kataklar eng balandiga tenglashadi va ajratuvchi
    // chiziqlar butun qator bo'ylab uzluksiz tushadi. Usiz «stretch»
    // cheksiz balandlik so'rab, chizish yiqiladi.
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _katak(
            _bobEni,
            child: Text(
              block.sarlavha,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
          for (final u in ustunlar)
            _katak(
              _katakEni,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _arabcha(u.ar, 14, FontWeight.w700),
                  if (u.ar2.isNotEmpty) _arabcha(u.ar2, 12.5, FontWeight.w400),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  Widget _bolimQatori(SarfQator q) => Container(
    color: AppColors.gold.withValues(alpha: 0.18),
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Center(child: _arabcha(q.bolim, 16, FontWeight.w800)),
  );

  Widget _qator(SarfQator q, int ustunSoni) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0x22000000))),
    ),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _katak(
            _bobEni,
            child: Text(
              q.bob,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: AppColors.indigo,
              ),
            ),
          ),
          for (var i = 0; i < ustunSoni; i++)
            _katak(
              _katakEni,
              child: i < q.kataklar.length
                  ? _katakIchi(q, i)
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    ),
  );

  /// Birinchi ustunda kitobdagidek qator raqami ham turadi.
  Widget _katakIchi(SarfQator q, int i) {
    final matn = q.kataklar[i];
    if (matn.isEmpty) return const SizedBox.shrink();
    final arabcha = _arabcha(matn, 16, FontWeight.w400);
    if (i != 0 || q.raqam.isEmpty) return arabcha;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${q.raqam})',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
            color: Colors.black45,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(child: arabcha),
      ],
    );
  }

  Widget _katak(double eni, {required Widget child}) => Container(
    width: eni,
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
    decoration: const BoxDecoration(
      border: Border(right: BorderSide(color: Color(0x22000000))),
    ),
    child: Center(child: child),
  );

  static final RegExp _arabHarf = RegExp('[؀-ۿ]');

  /// Katak matni. Arabcha bo'lsa Amiri bilan va o'ngdan chapga, o'zbekcha
  /// bo'lsa (ustun sarlavhalari kabi) oddiy shrift bilan chiziladi.
  Widget _arabcha(String matn, double olcham, FontWeight w) {
    if (!_arabHarf.hasMatch(matn)) {
      return Text(
        matn,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: olcham - 2, fontWeight: w, height: 1.25),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        matn,
        textAlign: TextAlign.center,
        style: AppTheme.arabic(size: olcham, color: AppColors.ink, w: w),
      ),
    );
  }
}

class _Royxat extends StatelessWidget {
  final SarfBlock block;
  const _Royxat({required this.block});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.intro.isNotEmpty) ...[
          AralashMatn(block.intro),
          const SizedBox(height: 6),
        ],
        for (var i = 0; i < block.items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: Text(
                    '${i + 1}.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                Expanded(child: AralashMatn(block.items[i])),
              ],
            ),
          ),
      ],
    );
  }
}
