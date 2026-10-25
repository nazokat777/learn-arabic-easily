import 'package:flutter/material.dart' hide Text;

import '../arabic.dart';
import '../content.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/speak_button.dart';
import '../widgets/uz_text.dart';
import 'lesson/sentence_text.dart';

/// Kitob tarjimasi — GAPMA-GAP, «Mashq: o'zbekchadan arabchaga» kartasi
/// ([TarjimaMashqi]) kabi: har arabcha gap alohida qatorda, o'quvchi avval
/// o'zi tarjima qilib ko'radi, keyin «Tarjima» bilan kitobdagi tarjimani
/// ochadi. Tepada «Hammasini ochish».
///
/// Matn kitobdagining o'zi (butun matni [QiroatLesson.translation]).
/// Kitobning tarjimasi erkin, shuning uchun:
///  * bitta o'zbekcha jumla ikki arabcha gapni qamrasa — ular bitta qatorda
///    yonma-yon ko'rsatiladi (raqami «3–4.»), tarjima bitta;
///  * kitob ba'zi gaplarni tarjima qilmagan — ularning tarjimasini ilova
///    qo'shgan va «ilova qo'shgan» deb ochiq belgilangan;
///  * she'r muallifining nomi kabi qatorlarda tarjima tugmasi yo'q.
class GapmaGapTarjima extends StatefulWidget {
  final QiroatLesson lesson;
  const GapmaGapTarjima({super.key, required this.lesson});

  @override
  State<GapmaGapTarjima> createState() => _GapmaGapTarjimaState();
}

class _GapmaGapTarjimaState extends State<GapmaGapTarjima> {
  late final List<String> _gaplar = splitSentences(widget.lesson.reading);

  /// Ochilgan guruhlar (tarjimaGuruhlari indeksi bo'yicha).
  final Set<int> _ochilgan = {};
  bool _sarlavhaOchiq = false;

  QiroatLesson get _l => widget.lesson;
  List<TarjimaGuruh> get _guruhlar => _l.tarjimaGuruhlari;
  bool get _sarlavhaBor => _l.tarjimaSarlavha.isNotEmpty;

  /// Tarjimasi bor (ochiladigan) guruhlar.
  List<int> get _ochiladigan => [
    for (var i = 0; i < _guruhlar.length; i++)
      if (_guruhlar[i].matn.isNotEmpty) i,
  ];

  bool get _hammasiOchiq =>
      _ochiladigan.every(_ochilgan.contains) &&
      (!_sarlavhaBor || _sarlavhaOchiq);

  void _hammasi() {
    setState(() {
      if (_hammasiOchiq) {
        _ochilgan.clear();
        _sarlavhaOchiq = false;
      } else {
        _ochilgan.addAll(_ochiladigan);
        _sarlavhaOchiq = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final guruhlar = _guruhlar;
    if (guruhlar.isEmpty) return const SizedBox.shrink();
    final birgalikda = guruhlar.any((g) => g.soni > 1 && g.matn.isNotEmpty);
    final qoshimcha = guruhlar.any((g) => g.qoshimcha);
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
              const Icon(Icons.translate_rounded, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tarjima — gapma-gap',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('gg-hammasi'),
                onPressed: _hammasi,
                child: Text(
                  _hammasiOchiq ? 'Yashirish' : 'Hammasini ochish',
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
            "Har bir gapni o'qing va avval o'zingiz tarjima qilib ko'ring, "
            "keyin «Tarjima» bilan kitobdagi tarjimani tekshiring.",
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.matn2,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (_sarlavhaBor) _sarlavhaQatori(),
          for (var gi = 0; gi < guruhlar.length; gi++) _guruhQatori(gi),
          if (birgalikda)
            Text(
              "Ba'zi gaplarning tarjimasi kitobda bitta jumlada birga "
              "berilgan — ular bitta qatorda ko'rsatilgan.",
              style: TextStyle(fontSize: 11.5, color: AppColors.matn3),
            ),
          if (qoshimcha)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "«Ilova qo'shgan» tarjima — kitob bu gapni tarjima qilmagan.",
                style: TextStyle(fontSize: 11.5, color: AppColors.matn3),
              ),
            ),
        ],
      ),
    );
  }

  /// «Tarjima» tugmasi yoki ochilgan tarjima paneli.
  Widget _tarjimaQismi({
    required bool ochiq,
    required String matn,
    required VoidCallback ochish,
    bool qoshimcha = false,
    Key? tugmaKey,
  }) {
    if (matn.isEmpty) return const SizedBox.shrink();
    if (!ochiq) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: tugmaKey,
          onPressed: () {
            Haptic.tap();
            ochish();
          },
          icon: const Icon(Icons.visibility_rounded, size: 17),
          label: const Text(
            'Tarjima',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.indigo,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: const Size(44, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }
    return TarjimaPaneli(matn: matn, qoshimcha: qoshimcha);
  }

  Widget _sarlavhaQatori() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 26,
          child: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.title_rounded, size: 18, color: AppColors.gold),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _l.titleAr,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTheme.arabic(
                  size: 22,
                  color: AppColors.emerald,
                  w: FontWeight.w700,
                ),
              ),
              _tarjimaQismi(
                ochiq: _sarlavhaOchiq,
                matn: _l.tarjimaSarlavha,
                ochish: () => setState(() => _sarlavhaOchiq = true),
                tugmaKey: const ValueKey('gg-sarlavha'),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _guruhQatori(int gi) {
    final g = _guruhlar[gi];
    final belgi = g.soni == 1
        ? '${g.boshi + 1}.'
        : '${g.boshi + 1}–${g.boshi + g.soni}.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: g.soni == 1 ? 26 : 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                belgi,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var k = g.boshi; k < g.boshi + g.soni; k++)
                  if (k < _gaplar.length)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SpeakButton(text: _gaplar[k], id: 'gg$k', size: 17),
                        Expanded(
                          child: SentenceText(
                            sentence: _gaplar[k],
                            vocab: _l.vocab,
                            reading: _l.reading,
                            lessonId: _l.completionId,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _tarjimaQismi(
                    ochiq: _ochilgan.contains(gi),
                    matn: g.matn,
                    qoshimcha: g.qoshimcha,
                    ochish: () => setState(() => _ochilgan.add(gi)),
                    tugmaKey: ValueKey('gg-tarjima-$gi'),
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

/// Ochilgan tarjima paneli: o'zbekcha matn; [qoshimcha] bo'lsa — «ilova
/// qo'shgan» belgisi bilan (kitobda bu gapning tarjimasi yo'q).
class TarjimaPaneli extends StatelessWidget {
  final String matn;
  final bool qoshimcha;

  /// Panel tepasida kichik izoh (masalan, «3–4-gaplarning tarjimasi»).
  final String? izoh;
  const TarjimaPaneli({
    super.key,
    required this.matn,
    this.qoshimcha = false,
    this.izoh,
  });

  @override
  Widget build(BuildContext context) {
    final rang = qoshimcha ? AppColors.gold : AppColors.indigo;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: rang.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rang.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (izoh != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                izoh!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.matn3,
                ),
              ),
            ),
          Text(
            matn,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          if (qoshimcha)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: rang),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      "Ilova qo'shgan tarjima — kitobda bu gap tarjima qilinmagan.",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.matn2,
                        height: 1.3,
                      ),
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
