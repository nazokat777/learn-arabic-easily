import 'package:flutter/material.dart';
import '../main.dart';
import '../content.dart';
import '../theme.dart';

class LettersLesson extends StatelessWidget {
  const LettersLesson({super.key});

  @override
  Widget build(BuildContext context) {
    final letters = repo.letters;
    return Scaffold(
      appBar: AppBar(title: const Text('Harflar darsi')),
      body: GridView.builder(
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showDetail(context, L),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(L.ar, style: AppTheme.arabic(size: 40, color: AppColors.emerald)),
                      const SizedBox(height: 4),
                      Text(L.nameUz,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.ink)),
                      Text(L.translit, style: const TextStyle(color: Colors.black45, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, Letter L) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(L.ar, style: AppTheme.arabic(size: 90, color: AppColors.emerald)),
            const SizedBox(height: 4),
            Text('${L.nameUz}  ·  ${L.nameAr}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.ink)),
            Text('Talaffuz: ${L.translit}',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.softGreen, borderRadius: BorderRadius.circular(14)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🗣️ ', style: TextStyle(fontSize: 18)),
                  Expanded(child: Text('Махраж: ${L.makhrajUz}',
                      style: const TextStyle(color: AppColors.ink, height: 1.3))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Harfning 4 holati:',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _form('Alohida', L.isolated),
                _form('Boshda', L.initial),
                _form('O\'rtada', L.medial),
                _form('Oxirida', L.finalForm),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(String label, String glyph) => Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
            ),
            child: Center(child: Text(glyph, style: AppTheme.arabic(size: 34, color: AppColors.ink))),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        ],
      );
}
