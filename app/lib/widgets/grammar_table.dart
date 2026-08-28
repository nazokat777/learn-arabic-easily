import 'package:flutter/material.dart';

import '../content.dart';
import '../theme.dart';
import 'speak_button.dart';

/// Kitobdagi grammatika jadvali.
///
/// Qiroat darslarida ham, nahv darslarida ham bir xil ko'rinadi, shuning
/// uchun ekranlardan chiqarib, umumiy vidjet qilindi.
class GrammarTable extends StatelessWidget {
  final QiroatTable table;
  const GrammarTable({super.key, required this.table});

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
          child: Text(table.titleAr,
              textDirection: TextDirection.rtl,
              style: AppTheme.arabic(size: 20, color: AppColors.emerald)),
        ),
        const SizedBox(height: 10),
        for (final g in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(g.key,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 13)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < r.cells.length; i += 2) _pair(r.cells[i], r.cells[i + 1]),
          ],
        ),
      );

  /// Fe'l boblari jadvalining bir qatori: har bir katak o'z ustun sarlavhasi
  /// bilan. Kitobda «——» turgan kataklar (bunday shakl yo'q) tashlab ketiladi.
  Widget _gridRow(QiroatTableRow r) {
    final filled = <int>[
      for (var i = 0; i < r.cells.length; i++)
        if (r.cells[i].trim().isNotEmpty) i
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.label.isNotEmpty)
            Text('bob ${r.label}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 12)),
          for (final i in filled)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SpeakButton(text: r.cells[i], id: 'bob-${r.cells[i]}', size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(r.cells[i],
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: AppTheme.arabic(size: 19, color: AppColors.ink)),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 96,
                    child: Text(i < table.columns.length ? table.columns[i] : '',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: Colors.black45, fontSize: 11)),
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
            Text(ar,
                textDirection: TextDirection.rtl,
                style: AppTheme.arabic(size: 20, color: AppColors.ink)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(uz,
                  style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ),
          ],
        ),
      );
}


/// Yopiladigan bo'lim - tarjima va mashq uchun.
///
/// Yopiq turadi: avval o'quvchi matnni o'zi tushunishga urinsin, keyin
/// ochib tekshirsin. Mashq ham shunday - oldindan ko'zga tashlanmasin.