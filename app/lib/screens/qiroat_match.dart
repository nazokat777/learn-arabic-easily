import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import '../content.dart';
import '../theme.dart';

/// «Juftlash o'yini» — arabcha so'zni o'zbekcha ma'nosi bilan moslashtirish.
/// So'zlar 5 tadan guruhlarga bo'linadi; barchasi juftlanguncha davom etadi.
class QiroatMatchGame extends StatefulWidget {
  final QiroatLesson lesson;
  const QiroatMatchGame({super.key, required this.lesson});

  @override
  State<QiroatMatchGame> createState() => _QiroatMatchGameState();
}

class _QiroatMatchGameState extends State<QiroatMatchGame> {
  static const _batchSize = 5;
  final _rnd = Random();

  late List<QiroatVocab> _all; // takrorlanmas so'zlar
  int _pos = 0; // navbatdagi guruh boshlanish indeksi
  int _matchedTotal = 0;
  int _mistakes = 0;
  int _xp = 0;

  late List<QiroatVocab> _left; // arabcha ustun (tartibda)
  late List<QiroatVocab> _right; // o'zbekcha ustun (aralash)
  final Set<QiroatVocab> _matched = {};
  int? _selLeft;
  int? _selRight;
  bool _wrong = false; // xato juft (qizil chaqnash)

  @override
  void initState() {
    super.initState();
    final seen = <String>{};
    _all = [];
    for (final v in widget.lesson.vocab) {
      if (v.uz.trim().isEmpty || v.ar.trim().isEmpty) continue;
      if (seen.add(v.uz)) _all.add(v);
    }
    _all.shuffle(_rnd);
    _loadBatch();
  }

  void _loadBatch() {
    final batch = _all.skip(_pos).take(_batchSize).toList();
    _left = List<QiroatVocab>.from(batch);
    _right = List<QiroatVocab>.from(batch)..shuffle(_rnd);
    _matched.clear();
    _selLeft = null;
    _selRight = null;
    _wrong = false;
  }

  void _tapLeft(int i) {
    if (_matched.contains(_left[i]) || _wrong) return;
    setState(() => _selLeft = i);
    _check();
  }

  void _tapRight(int j) {
    if (_matched.contains(_right[j]) || _wrong) return;
    setState(() => _selRight = j);
    _check();
  }

  void _check() {
    if (_selLeft == null || _selRight == null) return;
    final ok = _left[_selLeft!] == _right[_selRight!];
    if (ok) {
      final word = _left[_selLeft!];
      // Juftlash ham so'z yodlash darajasiga hissa qo'shadi (+1).
      progress.bumpWord('${widget.lesson.completionId}::${word.ar}', true);
      setState(() {
        _matched.add(word);
        _matchedTotal++;
        _xp += 3;
        _selLeft = null;
        _selRight = null;
      });
      if (_matched.length == _left.length) {
        // guruh tugadi — keyingisi yoki yakun
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          setState(() {
            _pos += _batchSize;
            if (_pos < _all.length) {
              _loadBatch();
            }
          });
          if (_pos >= _all.length) _finish();
        });
      }
    } else {
      setState(() {
        _mistakes++;
        _wrong = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _wrong = false;
          _selLeft = null;
          _selRight = null;
        });
      });
    }
  }

  Future<void> _finish() async {
    await progress.addXp(_xp);
    await progress.markCompleted('match_${widget.lesson.completionId}');
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text('Ajoyib!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.emerald)),
              const SizedBox(height: 8),
              Text('${_all.length} juft · $_mistakes xato · +$_xp XP',
                  style: const TextStyle(fontSize: 15, color: Colors.black54)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _pos = 0;
                          _matchedTotal = 0;
                          _mistakes = 0;
                          _xp = 0;
                          _all.shuffle(_rnd);
                          _loadBatch();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.emerald),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Yana',
                          style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tayyor', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lesson.num}-dars — juftlash'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: _all.isEmpty ? 0 : _matchedTotal / _all.length,
            minHeight: 6,
            backgroundColor: AppColors.softGreen,
            valueColor: const AlwaysStoppedAnimation(AppColors.success),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            const Text('Arabcha so\'zni ma\'nosi bilan juftlang',
                style: TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabcha ustun
                  Expanded(
                    child: Column(
                      children: List.generate(
                          _left.length, (i) => _tile(i, true)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // O'zbekcha ustun
                  Expanded(
                    child: Column(
                      children: List.generate(
                          _right.length, (j) => _tile(j, false)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(int idx, bool isLeft) {
    final word = isLeft ? _left[idx] : _right[idx];
    final selected = isLeft ? _selLeft == idx : _selRight == idx;
    final done = _matched.contains(word);

    Color bg = Colors.white;
    Color border = Colors.black12;
    if (done) {
      bg = AppColors.success.withValues(alpha: 0.12);
      border = AppColors.success.withValues(alpha: 0.5);
    } else if (selected) {
      if (_wrong) {
        bg = AppColors.coral.withValues(alpha: 0.12);
        border = AppColors.coral;
      } else {
        bg = AppColors.gold.withValues(alpha: 0.15);
        border = AppColors.gold;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: done ? null : () => isLeft ? _tapLeft(idx) : _tapRight(idx),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 58),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.8),
            ),
            child: Opacity(
              opacity: done ? 0.55 : 1,
              child: isLeft
                  ? Directionality(
                      textDirection: TextDirection.rtl,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_firstForm(word.ar),
                            style: AppTheme.arabic(size: 24, color: AppColors.emerald)),
                      ),
                    )
                  : Text(word.uz,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ),
          ),
        ),
      ),
    );
  }

  /// Fe'l 4 shaklli bo'lsa (vergul bilan), faqat birinchi shaklni ko'rsatamiz —
  /// o'yin tugmasi qisqa va o'qilishi oson bo'lsin uchun.
  String _firstForm(String ar) {
    final i = ar.indexOf('،');
    return i > 0 ? ar.substring(0, i).trim() : ar;
  }
}
