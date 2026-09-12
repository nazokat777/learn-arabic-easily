import 'package:flutter/material.dart' hide Text;

import '../content.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/speak_button.dart';
import '../widgets/uz_text.dart';
import 'lesson/sentence_text.dart';
import 'lesson/vocab_flow.dart' show AwardXp;

/// Kitobdagi «Quyidagi gaplarni arab tiliga tarjima qiling» mashqi —
/// interaktiv: har o'zbekcha jumla alohida, o'quvchi avval o'zi tarjima
/// qiladi, keyin javobni ochadi.
///
/// Mazmun kitobdagining o'zi. Jumlalar soni javob bilan mos kelsa —
/// har jumlaning javobi alohida ochiladi; mos kelmasa (kitobda
/// «Bu nima? Daftar.» kabi qo'shma javoblar bor) — noto'g'ri juftlab
/// qo'ymaslik uchun javob butunligicha ochiladi.
class TarjimaMashqi extends StatefulWidget {
  final QiroatLesson lesson;
  const TarjimaMashqi({super.key, required this.lesson});

  /// Jumlalarga ajratish: nuqta, so'roq, undov (arabcha ؟ ham) dan keyin.
  static List<String> jumlalar(String matn) => matn
      .split(RegExp(r'(?<=[.?!؟])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// (ko'rsatma, o'zbekcha jumlalar, arabcha javoblar yoki null — mos kelmasa)
  static (String, List<String>, List<String>?) ajrat(QiroatLesson l) {
    var uz = jumlalar(l.exercise);
    var korsatma = '';
    if (uz.isNotEmpty && uz.first.toLowerCase().startsWith('quyidagi')) {
      korsatma = uz.first;
      uz = uz.sublist(1);
    }
    final ar = jumlalar(l.exerciseAnswer);
    final mos = ar.isNotEmpty && ar.length == uz.length;
    return (korsatma, uz, mos ? ar : null);
  }

  @override
  State<TarjimaMashqi> createState() => _TarjimaMashqiState();
}

class _TarjimaMashqiState extends State<TarjimaMashqi> {
  final Set<int> _ochilgan = {};
  bool _butunOchiq = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final (korsatma, uz, ar) = TarjimaMashqi.ajrat(l);
    if (uz.isEmpty) return const SizedBox.shrink();
    final hammasi = ar != null && _ochilgan.length == uz.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.karta,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Mashq: o'zbekchadan arabchaga",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (ar != null)
                TextButton(
                  onPressed: () => setState(() {
                    if (hammasi) {
                      _ochilgan.clear();
                    } else {
                      _ochilgan.addAll(List.generate(uz.length, (i) => i));
                    }
                  }),
                  child: Text(
                    hammasi ? 'Yashirish' : 'Hammasini ochish',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.indigo,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            korsatma.isEmpty
                ? 'Avval o\'zingiz tarjima qiling, keyin javobni oching.'
                : "$korsatma Avval o'zingiz, keyin javobni oching.",
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.matn2,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          for (final (i, jumla) in uz.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1}.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          jumla,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (ar != null && !_ochilgan.contains(i))
                        TextButton(
                          onPressed: () {
                            Haptic.tap();
                            setState(() => _ochilgan.add(i));
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.indigo,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(44, 36),
                          ),
                          child: const Text(
                            'Javob',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (ar != null && _ochilgan.contains(i))
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SpeakButton(text: ar[i], id: 'tarjima-$i', size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: SentenceText(
                              sentence: ar[i],
                              vocab: l.vocab,
                              reading: l.reading,
                              size: 21,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (ar == null && l.exerciseAnswer.isNotEmpty) ...[
            const SizedBox(height: 4),
            if (!_butunOchiq)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Haptic.tap();
                    setState(() => _butunOchiq = true);
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text(
                    'Javobni ko\'rish',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.indigo,
                    side: const BorderSide(color: AppColors.indigo),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpeakButton(
                    text: l.exerciseAnswer,
                    id: 'tarjima-hammasi',
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SentenceText(
                      sentence: l.exerciseAnswer,
                      vocab: l.vocab,
                      reading: l.reading,
                      size: 21,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// Dars oqimidagi «Tarjima» bosqichi: kitob mashqi + «Savollarga o'tish».
/// Bosqich uchun +5 ball — mashqni ochib ko'rganga emas, o'tganga.
class TarjimaStage extends StatelessWidget {
  final QiroatLesson lesson;
  final VoidCallback onDone;
  final AwardXp award;
  const TarjimaStage({
    super.key,
    required this.lesson,
    required this.onDone,
    required this.award,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 18,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "O'zbekchadan arabchaga",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Kitobdagi mashq. Har gapni o'zingiz arabcha ayting (yoki "
                "yozing), keyin «Javob» bilan tekshiring.",
                style: TextStyle(fontSize: 11.5, color: AppColors.matn3),
              ),
              const SizedBox(height: 10),
              TarjimaMashqi(lesson: lesson),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                award(5);
                onDone();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Savollarga o'tish",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
