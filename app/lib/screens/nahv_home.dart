import 'package:flutter/material.dart' hide Text;
import 'gap_tuzish_ekrani.dart';
import '../widgets/uz_text.dart';

import '../main.dart';
import '../content.dart';
import '../mashq/bank.dart';
import '../mashq/mashq_ekran.dart';
import '../theme.dart';
import '../widgets/aralash_matn.dart';
import '../widgets/entrance.dart';
import '../widgets/mastery_badge.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import '../widgets/premium_tile.dart';
import '../widgets/yol.dart';
import '../widgets/grammar_table.dart';
import '../widgets/speak_button.dart';
import 'lesson/sentence_text.dart';

/// «Nahv» — arab tili grammatikasi (jumla tuzilishi) bo'limi.
///
/// Manba: «الدروس النحوية» — TO'LIQ arabcha kitob. Shuning uchun bu bo'lim
/// qolganlaridan bir narsa bilan farq qiladi: arabcha matn kitobniki, ammo
/// o'zbekchasi TARJIMA - kitobda o'zbekcha matn umuman yo'q. Shuning uchun
/// har bir darsda ikkalasi yonma-yon ko'rsatiladi, o'quvchi asliyatni ham
/// ko'rib tursin.
class NahvHome extends StatelessWidget {
  const NahvHome({super.key});

  @override
  Widget build(BuildContext context) {
    final lessons = repo.nahvLessons;
    return Scaffold(
      appBar: AppBar(title: const Text('Nahv')),
      body: ListView(
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
                  'نَحْو',
                  style: AppTheme.arabic(size: 30, color: AppColors.emerald),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '«الدروس النحوية» — jumla tuzilishi. Kitob arabcha; '
                    'o\'zbekchasi tarjima qilib berilgan.',
                    style: TextStyle(color: AppColors.ink, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (lessons.isEmpty)
            Text(
              'Darslar hali qo\'shilmagan.',
              style: TextStyle(color: AppColors.matn2),
            )
          else
            // Kitoblar bo'yicha ajratamiz: dars raqamlari har kitobda
            // qaytadan boshlanadi, aralashsa o'quvchi adashadi.
            ...() {
              final out = <Widget>[];
              final joriy = lessons.indexWhere(
                (l) => !progress.isMastered('nahv-${l.book}-${l.num}'),
              );
              int? oxirgiKitob;
              for (var i = 0; i < lessons.length; i++) {
                final l = lessons[i];
                if (l.book != oxirgiKitob) {
                  oxirgiKitob = l.book;
                  out.add(
                    Padding(
                      padding: EdgeInsets.only(
                        top: i == 0 ? 0 : 14,
                        bottom: 10,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${l.book}-kitob',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.gold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(child: Divider(height: 1)),
                        ],
                      ),
                    ),
                  );
                }
                out.add(
                  EntranceFade(
                    delay: Duration(milliseconds: 40 + (i < 12 ? i : 12) * 45),
                    child: YolBand(
                      rang: AppColors.coral,
                      birinchi: i == 0,
                      oxirgi: i == lessons.length - 1,
                      bajarildi: progress.isMastered('nahv-${l.book}-${l.num}'),
                      joriy: i == joriy,
                      child: _tile(context, l),
                    ),
                  ),
                );
              }
              return out;
            }(),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, NahvLesson l) => PremiumTile(
    title: l.title,
    subtitle: () {
      final n = MashqBank.nahvDars(l).length;
      // Bo'sh holat raqam bilan («0 ta mashq») xato kabi ko'rinardi.
      return n == 0 ? 'Nazariy dars — takror bilan' : '$n ta mashq';
    }(),
    arabicSubtitle: l.titleAr,
    label: '${l.num}',
    accent: AppColors.coral,
    // O'zlashtirish holati: belgi faqat test XATOSIZ o'tilganda chiqadi.
    // Shunchaki darsni ochib chiqish belgi bermaydi.
    trailing: MasteryBadge(lessonId: 'nahv-${l.book}-${l.num}', size: 22),
    onTap: () {
      progress.oxirgiDarsniYoz(
        'nahv',
        'nahv-${l.book}-${l.num}',
        'Nahv · ${l.book}-kitob, ${l.num}-dars',
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NahvLessonScreen(lesson: l)),
      );
    },
  );
}

/// Bitta nahv darsi: qoida, izoh va misollar.
class NahvLessonScreen extends StatefulWidget {
  final NahvLesson lesson;
  const NahvLessonScreen({super.key, required this.lesson});

  @override
  State<NahvLessonScreen> createState() => _NahvLessonScreenState();
}

class _NahvLessonScreenState extends State<NahvLessonScreen> {
  NahvLesson get lesson => widget.lesson;

  /// Tarjimalar yashirin: o'quvchi arabcha bandni o'qib, avval o'zi
  /// tushunishga urinadi, keyin tarjimani ochib tekshiradi. Qoida
  /// ramkasi ochiq qoladi — u darsning tayanchi. Kitob mazmuni
  /// o'zgarmaydi, faqat ko'rsatish tartibi.
  bool _tarjimaYashirin = false;

  Widget _sinashTugmasi() => Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: () => setState(() => _tarjimaYashirin = !_tarjimaYashirin),
      icon: Icon(
        _tarjimaYashirin ? Icons.visibility_rounded : Icons.psychology_rounded,
        size: 16,
      ),
      label: Text(
        _tarjimaYashirin
            ? 'Tarjimalarni ko\'rsatish'
            : 'Tarjimasiz o\'qib sinayman',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.indigo,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(44, 40),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final y = _tarjimaYashirin;
    return Scaffold(
      appBar: AppBar(title: Text('${lesson.num}-dars')),
      // Matn ustuni cheklanadi: keng ekranda (planshet, brauzer) arabcha
      // satrlar butun kenglikka cho'zilib ketadi va ko'z satr boshini
      // yo'qotadi — ayniqsa o'ngdan chapga o'qilganda.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Center(
                child: Text(
                  lesson.titleAr,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabic(
                    size: 28,
                    color: AppColors.emerald,
                    w: FontWeight.w700,
                  ),
                ),
              ),
              Center(
                child: Text(
                  lesson.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.matn2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Qoida - kitobda ramka ichida beriladi, bu yerda ham ajratib turadi.
              if (lesson.rule.ar.isNotEmpty) _RuleBox(rule: lesson.rule),
              const SizedBox(height: 6),
              _sinashTugmasi(),
              const SizedBox(height: 6),
              for (final b in lesson.blocks) ...[
                if (b.type == 'list' && (b.intro?.ar.isNotEmpty ?? false))
                  _Bilingual(pair: b.intro!, yashirin: y),
                if (b.type != 'list') _Bilingual(pair: b.main!, yashirin: y),
                if (b.type == 'list')
                  for (var i = 0; i < b.items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 2),
                      child: _Bilingual(
                        pair: b.items[i],
                        bullet: '${i + 1}.',
                        yashirin: y,
                      ),
                    ),
                const SizedBox(height: 12),
              ],
              for (final t in lesson.tables) ...[
                const SizedBox(height: 8),
                GrammarTable(table: t),
                const SizedBox(height: 8),
              ],
              if (lesson.exercise.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: AppColors.emerald,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mashq — تَمْرِينٌ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold,
                      ),
                    ),
                    const Spacer(),
                    // Mashq gaplari o'yin ko'rinishida: so'zlardan tuzish.
                    if (lesson.exercise.length >= 2)
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GapTuzishEkrani(
                              juftlar: [
                                for (final j in lesson.exercise) (j.uz, j.ar),
                              ],
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.extension_rounded, size: 16),
                        label: const Text(
                          'Gap tuzish',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.indigo,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          minimumSize: const Size(44, 40),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < lesson.exercise.length; i++)
                  _Bilingual(
                    pair: lesson.exercise[i],
                    bullet: '${i + 1}.',
                    yashirin: y,
                  ),
              ],
              const SizedBox(height: 20),
              // Duolingo uslubidagi test: darsdagi juftliklardan avtomatik
              // tuziladi, xato savollar to'g'ri yechilguncha qaytaveradi.
              // Dars «o'zlashtirildi» belgisini faqat xatosiz o'tishda oladi.
              MasteryCallToAction(
                lessonId: 'nahv-${lesson.book}-${lesson.num}',
                what: 'qoida va misollar',
                onStart: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MashqEkran(
                      sarlavha: '${lesson.num}-dars mashqi',
                      darsniki: MashqBank.nahvDars(lesson),
                      oldingilar: MashqBank.nahvGacha(lesson),
                      darsId: 'nahv-${lesson.book}-${lesson.num}',
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
}

/// Kitobdagi ramkali qoida.
class _RuleBox extends StatelessWidget {
  final NahvPair rule;
  const _RuleBox({required this.rule});

  @override
  Widget build(BuildContext context) {
    // Qoida — darsning yuragi. Kitobda ramkada; bu yerda oltin chetli,
    // ichi yumshoq gradientli karta, kattaroq arabcha va bezak chizig'i —
    // ko'z avval shunga tushsin.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.karta, AppColors.softGreen],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            const Positioned.fill(
              child: GirihPattern(
                color: AppColors.gold,
                opacity: 0.05,
                cell: 44,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: AppColors.gold),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'QOIDA',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                          fontSize: 12,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),
                      SpeakButton(
                        text: rule.ar,
                        id: 'nahv-qoida-${rule.ar}',
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _Bilingual(pair: rule, arabicSize: 25),
                  const OrnamentDivider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Arabcha matn (tinglash tugmasi va bosiladigan so'zlar bilan) va uning
/// tagida o'zbekcha tarjimasi.
class _Bilingual extends StatefulWidget {
  final NahvPair pair;
  final String? bullet;
  final double arabicSize;

  /// Sinash rejimi: tarjima bosilguncha yopiq.
  final bool yashirin;
  const _Bilingual({
    required this.pair,
    this.bullet,
    this.arabicSize = 20,
    this.yashirin = false,
  });

  @override
  State<_Bilingual> createState() => _BilingualState();
}

class _BilingualState extends State<_Bilingual> {
  bool _ochildi = false;

  @override
  void didUpdateWidget(covariant _Bilingual old) {
    super.didUpdateWidget(old);
    if (old.yashirin != widget.yashirin) _ochildi = false;
  }

  bool get _ochiq => !widget.yashirin || _ochildi;

  Widget _tarjima() {
    if (_ochiq) {
      // Tarjima ichida arabcha parchalar bo'ladi («بِسْمِ الله» kabi) —
      // ular Amiri bilan, bosilsa o'qib beriladigan qilib chiziladi; oddiy
      // Text'da ular zaxira shriftga tushib, ba'zan kvadrat bo'lib qoladi.
      return AralashMatn(
        widget.pair.uz,
        uslub: TextStyle(fontSize: 14, color: AppColors.matn2, height: 1.35),
        arabchaOlchami: 18,
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Haptic.tap();
        setState(() => _ochildi = true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.indigo.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.indigo.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline_rounded,
              size: 15,
              color: AppColors.indigo.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Text(
              'Tarjimasi — avval o\'zingiz, keyin bosing',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pair = widget.pair;
    final bullet = widget.bullet;
    final arabicSize = widget.arabicSize;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bullet != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 2),
                  child: Text(
                    bullet,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              SpeakButton(text: pair.ar, id: 'nahv-${pair.ar}', size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: SentenceText(
                  sentence: pair.ar,
                  vocab: const [],
                  reading: '',
                  size: arabicSize,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 2),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(key: ValueKey(_ochiq), child: _tarjima()),
            ),
          ),
        ],
      ),
    );
  }
}
