import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import '../content.dart';
import '../theme.dart';
import '../widgets/speak_button.dart';

/// Harakatlarni (diakritik belgilarni) olib tashlab, faqat asosiy harflarni qaytaradi.
List<String> baseLetters(String ar) {
  final stripped = ar.replaceAll(RegExp('[ً-ٰٟـ]'), '');
  return stripped.split('').where((c) => c.trim().isNotEmpty).toList();
}

class WordGame extends StatefulWidget {
  const WordGame({super.key});
  @override
  State<WordGame> createState() => _WordGameState();
}

class _WordGameState extends State<WordGame> {
  final _rnd = Random();
  late List<VocabWord> _pool;
  late VocabWord _word;
  late List<String> _target; // to'g'ri harflar ketma-ketligi (mantiqiy tartib)
  late List<_Tile> _tiles; // aralashtirilgan harf tugmalari
  final List<int> _picked = []; // tanlangan tile indekslari (tartib bilan)
  bool? _result; // null=davom, true=to'g'ri, false=xato
  int _solved = 0;

  @override
  void initState() {
    super.initState();
    // 3-5 harfli so'zlarni tanlaymiz (o'yin uchun qulay)
    _pool = repo.words.where((w) {
      final n = baseLetters(w.ar).length;
      return n >= 3 && n <= 5;
    }).toList()
      ..shuffle(_rnd);
    _load(0);
  }

  void _load(int i) {
    _word = _pool[i % _pool.length];
    _target = baseLetters(_word.ar);
    final shuffled = List<String>.from(_target)..shuffle(_rnd);
    // Agar tasodifan to'g'ri tartibda chiqsa, qayta aralash
    if (shuffled.join() == _target.join() && _target.length > 1) {
      shuffled.shuffle(_rnd);
    }
    _tiles = List.generate(shuffled.length, (k) => _Tile(shuffled[k], k));
    _picked.clear();
    _result = null;
  }

  void _tap(int tileIndex) {
    if (_result != null) return;
    if (_picked.contains(tileIndex)) return;
    setState(() {
      _picked.add(tileIndex);
      if (_picked.length == _target.length) _check();
    });
  }

  void _undo() {
    if (_result != null || _picked.isEmpty) return;
    setState(() => _picked.removeLast());
  }

  Future<void> _check() async {
    final built = _picked.map((i) => _tiles[i].letter).toList();
    final ok = built.join() == _target.join();
    setState(() => _result = ok);
    if (ok) {
      _solved++;
      await progress.addXp(8);
      if (_solved >= 5) await progress.markCompleted('word_game');
    }
  }

  void _nextWord() {
    setState(() => _load(_rnd.nextInt(_pool.length)));
  }

  @override
  Widget build(BuildContext context) {
    final built = _picked.map((i) => _tiles[i].letter).join();
    return Scaffold(
      appBar: AppBar(title: const Text('So\'z yasash o\'yini')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Tuzing:', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text('«${_word.uz}»',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.emerald)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Yig'ilayotgan so'z
            Container(
              height: 90,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _result == null
                      ? Colors.black12
                      : _result!
                          ? AppColors.success
                          : AppColors.coral,
                  width: 2,
                ),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(built.isEmpty ? '…' : built,
                    style: AppTheme.arabic(size: 52, color: AppColors.ink)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: _result == null
                  ? (_picked.isNotEmpty
                      ? TextButton.icon(
                          onPressed: _undo,
                          icon: const Icon(Icons.backspace_outlined, size: 18),
                          label: const Text('Orqaga'))
                      : const SizedBox())
                  : Text(
                      _result! ? '✅ To\'g\'ri! +8 XP' : '❌ Noto\'g\'ri, qayta urinib ko\'ring',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _result! ? AppColors.success : AppColors.coral)),
            ),
            const SizedBox(height: 24),
            // Harf tugmalari
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(_tiles.length, (i) {
                final used = _picked.contains(i);
                return GestureDetector(
                  onTap: () => _tap(i),
                  child: AnimatedOpacity(
                    opacity: used ? 0.25 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                      ),
                      child: Center(
                        child: Text(_tiles[i].letter, style: AppTheme.arabic(size: 36, color: AppColors.emerald)),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),
            if (_result != null)
              Column(
                children: [
                  if (_result!)
                    // To'g'ri yig'ilgan so'zni eshitib ham ko'radi.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(_word.ar,
                              style: AppTheme.arabic(size: 40, color: AppColors.gold)),
                        ),
                        const SizedBox(width: 8),
                        SpeakButton(text: _word.ar, id: 'oyin-${_word.ar}', size: 24),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!_result!)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() {
                              _picked.clear();
                              _result = null;
                            }),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.coral),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Qayta', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      if (!_result!) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _nextWord,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Keyingi so\'z', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Tile {
  final String letter;
  final int id;
  _Tile(this.letter, this.id);
}
