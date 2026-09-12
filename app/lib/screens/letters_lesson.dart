import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';
import '../main.dart';
import '../arabic.dart';
import '../content.dart';
import '../theme.dart';
import '../widgets/harf_holati.dart';
import '../widgets/mastery_badge.dart';
import '../widgets/speak_button.dart';
import 'letter_test.dart';

class LettersLesson extends StatelessWidget {
  const LettersLesson({super.key});

  @override
  Widget build(BuildContext context) {
    final letters = repo.letters;
    return Scaffold(
      appBar: AppBar(title: const Text('Harflar darsi')),
      // Panjara + pastda test chaqirig'i: harflarni ko'rib chiqish
      // o'rganish emas, mavzu testda xatosiz o'tilishi kerak.
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: letters.length,
              itemBuilder: (context, i) {
                final L = letters[i];
                return Material(
                  color: AppColors.karta,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showDetail(context, L),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              L.ar,
                              style: AppTheme.arabic(
                                size: 40,
                                color: AppColors.emerald,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              L.nameUz,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              L.translit,
                              style: TextStyle(
                                color: AppColors.matn3,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: MasteryCallToAction(
              lessonId: 'letter_test',
              what: '28 harf',
              onStart: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LetterTest()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Misol so'zlar lug'ati — bir marta yasaladi.
  ///
  /// Nega static: harf bosilganda minglab so'zni qaytadan saralash sekin.
  /// Qisqa so'zlar oldinda turadi — misol qisqa bo'lgani tushunarli.
  static List<({String ar, String uz})>? _lugatKesh;

  static List<({String ar, String uz})> get _lugat {
    if (_lugatKesh != null) return _lugatKesh!;
    final map = <String, String>{};
    for (final w in repo.words) {
      final ar = w.ar.trim();
      if (ar.isNotEmpty && w.uz.trim().isNotEmpty) {
        map.putIfAbsent(ar, () => w.uz.trim());
      }
    }
    for (final l in repo.qiroatLessons) {
      for (final v in l.vocab) {
        final ar = v.ar.split('،').first.trim();
        if (ar.isEmpty || v.uz.trim().isEmpty) continue;
        map.putIfAbsent(ar, () => v.uz.trim());
      }
    }
    final list = map.entries.map((e) => (ar: e.key, uz: e.value)).toList();
    list.sort(
      (a, b) =>
          stripDiacritics(a.ar).length.compareTo(stripDiacritics(b.ar).length),
    );
    return _lugatKesh = list;
  }

  void _showDetail(BuildContext context, Letter L) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.karta,
      // Bo'lim uzun — oyna balandligi cheklanadi va ichi aylanadi.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.chiziq2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  L.ar,
                  style: AppTheme.arabic(size: 90, color: AppColors.emerald),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${L.nameUz}  ·  ${L.nameAr}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Yolg'iz harfning o'zi emas, NOMI o'qiladi — ustoz ham
                    // shunday aytadi, va yolg'iz harfdan ovoz chiqmaydi.
                    SpeakButton(text: L.nameAr, id: 'harf-${L.ar}', size: 22),
                  ],
                ),
                Text(
                  'Talaffuz: ${L.translit}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.record_voice_over_rounded,
                        size: 18,
                        color: AppColors.emerald,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Maxraj: ${L.makhrajUz}',
                          style: TextStyle(color: AppColors.ink, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Harakatlar bilan tinglang:',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _syllable(L.ar, 'َ', 'a'), // fatha
                    _syllable(L.ar, 'ِ', 'i'), // kasra
                    _syllable(L.ar, 'ُ', 'u'), // zamma
                  ],
                ),
                const SizedBox(height: 22),
                HarfHolatiBolimi(letter: L, lugat: _lugat),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Harf + harakat: bosilganda o'sha bo'g'in eshitiladi (بَ، بِ، بُ).
  Widget _syllable(String letter, String sign, String sound) {
    final text = '$letter$sign';
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.softGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                text,
                style: AppTheme.arabic(size: 34, color: AppColors.emerald),
              ),
            ),
          ),
        ),
        SpeakButton(text: text, id: 'bogin-$text', size: 18),
        Text(sound, style: TextStyle(fontSize: 11.5, color: AppColors.matn2)),
      ],
    );
  }
}
