import 'package:flutter/material.dart' hide Text;
import 'uz_text.dart';

import '../content.dart';
import '../services/tts.dart';
import '../theme.dart';
import 'motion.dart';
import 'speak_button.dart';

/// Katakda arab harfi bormi.
final RegExp _arabHarf = RegExp('[ء-يٱ-ۓ]');
bool _arabchami(String s) => _arabHarf.hasMatch(s);

/// Kitobdagi grammatika jadvali.
///
/// Qiroat darslarida ham, nahv darslarida ham bir xil ko'rinadi, shuning
/// uchun ekranlardan chiqarib, umumiy vidjet qilindi.
class GrammarTable extends StatefulWidget {
  final QiroatTable table;
  const GrammarTable({super.key, required this.table});

  @override
  State<GrammarTable> createState() => _GrammarTableState();
}

/// Ikki rejim: ko'rish (kitobdagidek) va SINASH — arabcha shakllar
/// yopiladi, ma'no/ustun nomi qoladi; o'quvchi avval eslab, keyin
/// katakni ochadi (ochilganda o'qib beriladi). Eslab chiqarish qayta
/// o'qishdan kuchli yodlash usuli; jadval mazmuni o'zgarmaydi.
class _GrammarTableState extends State<GrammarTable> {
  QiroatTable get table => widget.table;
  bool _sinash = false;
  final Set<String> _ochilgan = {};

  int get _arabchaSoni => [
    for (final r in table.rows)
      for (final c in r.cells)
        if (_arabchami(c)) c,
  ].toSet().length;

  /// Arabcha katak: sinashda yopiq «?» plitka, ochilgach — matn.
  Widget _yashirin(String ar, Widget ochiq, {required String id}) {
    if (!_sinash || _ochilgan.contains(ar)) return ochiq;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Haptic.tap();
        setState(() => _ochilgan.add(ar));
        Tts.instance.speak(ar, id: id);
      },
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.indigo.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.indigo.withValues(alpha: 0.3)),
        ),
        child: Icon(
          Icons.help_outline_rounded,
          size: 18,
          color: AppColors.indigo.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _sinashTugmasi() {
    final jami = _arabchaSoni;
    if (jami < 2) return const SizedBox.shrink();
    return Row(
      children: [
        if (_sinash)
          Expanded(
            child: Text(
              _ochilgan.length >= jami
                  ? "Hammasi ochildi — yana sinab ko'ring"
                  : '${_ochilgan.length} / $jami ochildi · avval eslang',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _ochilgan.length >= jami
                    ? AppColors.success
                    : AppColors.matn2,
              ),
            ),
          )
        else
          const Spacer(),
        TextButton.icon(
          onPressed: () => setState(() {
            _sinash = !_sinash;
            _ochilgan.clear();
          }),
          icon: Icon(
            _sinash ? Icons.visibility_rounded : Icons.psychology_rounded,
            size: 16,
          ),
          label: Text(
            _sinash ? "Ko'rsatish" : "O'zimni sinayman",
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.indigo,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<QiroatTableRow>>{};
    for (final r in table.rows) {
      groups.putIfAbsent(r.group, () => []).add(r);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            table.titleAr,
            textDirection: TextDirection.rtl,
            style: AppTheme.arabic(size: 20, color: AppColors.emerald),
          ),
        ),
        _sinashTugmasi(),
        const SizedBox(height: 6),
        for (final g in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              g.key,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
                fontSize: 13,
              ),
            ),
          ),
          ...g.value.map(table.layout == 'grid' ? _gridRow : _row),
        ],
      ],
    );
  }

  Widget _row(QiroatTableRow r) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.karta,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < r.cells.length; i += 2)
          _pair(r.cells[i], r.cells[i + 1]),
      ],
    ),
  );

  /// Fe'l boblari jadvalining bir qatori: har bir katak o'z ustun sarlavhasi
  /// bilan. Kitobda «——» turgan kataklar (bunday shakl yo'q) tashlab ketiladi.
  Widget _gridRow(QiroatTableRow r) {
    final filled = <int>[
      for (var i = 0; i < r.cells.length; i++)
        if (r.cells[i].trim().isNotEmpty) i,
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.karta,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.label.isNotEmpty)
            Text(
              'bob ${r.label}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
                fontSize: 12,
              ),
            ),
          for (final i in filled)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // O'zbekcha izoh katagi (masalan zamirlar jadvalidagi
                  // «G'oyib ayol uchun») arabcha emas: uni o'qitib
                  // bo'lmaydi va arab shriftida chizish ham noto'g'ri.
                  if (_arabchami(r.cells[i]))
                    SpeakButton(
                      text: r.cells[i],
                      id: 'bob-${r.cells[i]}',
                      size: 18,
                    )
                  else
                    const SizedBox(width: 34),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _arabchami(r.cells[i])
                        ? _yashirin(
                            r.cells[i],
                            id: 'bob-${r.cells[i]}',
                            Text(
                              r.cells[i],
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: AppTheme.arabic(
                                size: 19,
                                color: AppColors.ink,
                              ),
                            ),
                          )
                        : Text(
                            r.cells[i],
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.matn2,
                              height: 1.3,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 96,
                    child: Text(
                      i < table.columns.length ? table.columns[i] : '',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: AppColors.matn3, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Bitta juftlik: arabcha shakl (tinglash tugmasi bilan) va ma'nosi.
  Widget _pair(String ar, String uz) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SpeakButton(text: ar, id: 'jadval-$ar', size: 18),
        const SizedBox(width: 6),
        _yashirin(
          ar,
          id: 'jadval-$ar',
          Text(
            ar,
            textDirection: TextDirection.rtl,
            style: AppTheme.arabic(size: 20, color: AppColors.ink),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            uz,
            style: TextStyle(color: AppColors.matn2, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

/// Yopiladigan bo'lim - tarjima va mashq uchun.
///
/// Yopiq turadi: avval o'quvchi matnni o'zi tushunishga urinsin, keyin
/// ochib tekshirsin. Mashq ham shunday - oldindan ko'zga tashlanmasin.
