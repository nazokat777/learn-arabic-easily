import 'dart:math';
import 'package:flutter/material.dart';
import '../../arabic.dart';
import '../../content.dart';
import '../../main.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import 'word_sheet.dart';

typedef AwardXp = void Function(int xp);

/// Lug'at bosqichi — so'zlar 5 tadan guruhlanadi:
///  guruh so'zlarini ochib tanish → shu 5 so'z bo'yicha mashq → keyingi guruh.
class VocabStage extends StatefulWidget {
  final QiroatLesson lesson;
  final VoidCallback onDone;
  final AwardXp award;
  const VocabStage({super.key, required this.lesson, required this.onDone, required this.award});

  @override
  State<VocabStage> createState() => _VocabStageState();
}

enum _Phase { learn, practice }

class _VocabStageState extends State<VocabStage> {
  final _rnd = Random();
  late List<QiroatVocab> _pool;
  late List<List<QiroatVocab>> _chunks;
  int _ci = 0; // guruh indeksi
  _Phase _phase = _Phase.learn;

  // learn
  int _li = 0;
  bool _revealed = false;

  // practice
  int _pi = 0;
  List<String> _opts = [];
  int _correct = 0;
  int? _picked;
  bool _answered = false;

  String _key(QiroatVocab v) => '${widget.lesson.completionId}::${v.ar}';

  @override
  void initState() {
    super.initState();
    final seen = <String>{};
    _pool = [];
    for (final v in widget.lesson.vocab) {
      if (v.ar.trim().isEmpty || v.uz.trim().isEmpty) continue;
      if (seen.add(v.uz)) _pool.add(v);
    }
    _chunks = [];
    for (var i = 0; i < _pool.length; i += 5) {
      _chunks.add(_pool.sublist(i, min(i + 5, _pool.length)));
    }
    if (_chunks.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
    }
  }

  List<QiroatVocab> get _chunk => _chunks[_ci];

  QiroatVocab get _card => _chunk[_li];

  void _reveal() {
    setState(() => _revealed = true);
    Tts.instance.speak(splitForms(_card.ar).first, id: 'card');
  }

  void _nextCard() {
    if (_li + 1 < _chunk.length) {
      setState(() {
        _li++;
        _revealed = false;
      });
    } else {
      // mashqqa o'tamiz
      setState(() {
        _phase = _Phase.practice;
        _pi = 0;
      });
      _buildQuestion();
    }
  }

  void _buildQuestion() {
    final word = _chunk[_pi];
    final distract = _pool
        .where((v) => v.uz != word.uz)
        .map((v) => v.uz)
        .toSet()
        .toList()
      ..shuffle(_rnd);
    _opts = <String>[word.uz, ...distract.take(3)]..shuffle(_rnd);
    _correct = _opts.indexOf(word.uz);
    _picked = null;
    _answered = false;
    setState(() {});
  }

  Future<void> _answer(int i) async {
    if (_answered) return;
    final word = _chunk[_pi];
    final ok = i == _correct;
    setState(() {
      _picked = i;
      _answered = true;
    });
    if (ok) widget.award(1);
    await progress.bumpWord(_key(word), ok);
    Future.delayed(Duration(milliseconds: ok ? 600 : 1200), () {
      if (!mounted) return;
      if (_pi + 1 < _chunk.length) {
        setState(() => _pi++);
        _buildQuestion();
      } else {
        _nextChunk();
      }
    });
  }

  void _nextChunk() {
    if (_ci + 1 < _chunks.length) {
      setState(() {
        _ci++;
        _phase = _Phase.learn;
        _li = 0;
        _revealed = false;
      });
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chunks.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _header(),
        Expanded(child: _phase == _Phase.learn ? _learnView() : _practiceView()),
      ],
    );
  }

  Widget _header() {
    final total = _chunks.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('So\'zlar guruhi ${_ci + 1} / $total',
                  style: const TextStyle(fontSize: 12.5, color: Colors.black54, fontWeight: FontWeight.w700)),
              Text(_phase == _Phase.learn ? 'Tanishuv' : 'Mashq',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.gold, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_ci + (_phase == _Phase.practice ? 0.5 : 0.0)) / total,
              minHeight: 8,
              backgroundColor: AppColors.softGreen,
              valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tanishuv (recall card: bosib ochish) ---
  Widget _learnView() {
    final v = _card;
    final head = splitForms(v.ar).first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
      child: Column(
        children: [
          Text('So\'z ${_li + 1} / ${_chunk.length}',
              style: const TextStyle(fontSize: 12, color: Colors.black38)),
          const SizedBox(height: 10),
          Expanded(
            child: GestureDetector(
              onTap: _revealed ? null : _reveal,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(head,
                          textAlign: TextAlign.center,
                          style: AppTheme.arabic(size: 52, color: AppColors.emerald, w: FontWeight.w700)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoundPlay(text: head),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () => showWordSheet(context, v, reading: widget.lesson.reading),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Batafsil'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.emerald,
                            side: const BorderSide(color: AppColors.emerald),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_revealed) ...[
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(v.uz,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 6),
                      Text('≈ ${approxTranslit(head)}',
                          style: const TextStyle(color: Colors.black45, fontStyle: FontStyle.italic)),
                    ] else
                      const Text('Ma\'nosini ko\'rish uchun kartani bosing',
                          style: TextStyle(color: Colors.black38, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _revealed ? _nextCard : _reveal,
              style: FilledButton.styleFrom(
                backgroundColor: _revealed ? AppColors.emerald : AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_revealed ? 'Keyingi so\'z' : 'Ochish',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Mashq (5 so'z bo'yicha tez test) ---
  Widget _practiceView() {
    final word = _chunk[_pi];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
      child: Column(
        children: [
          Text('Mashq ${_pi + 1} / ${_chunk.length}',
              style: const TextStyle(fontSize: 12, color: Colors.black38)),
          const Spacer(),
          const Text('Bu so\'z nima degani?', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(splitForms(word.ar).first,
                        textAlign: TextAlign.center,
                        style: AppTheme.arabic(size: 40, color: AppColors.emerald)),
                  ),
                ),
                const SizedBox(width: 8),
                _RoundPlay(text: splitForms(word.ar).first),
              ],
            ),
          ),
          const Spacer(),
          ...List.generate(_opts.length, (i) => _optTile(i)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _optTile(int i) {
    Color border = Colors.black12;
    Color bg = Colors.white;
    if (_answered) {
      if (i == _correct) {
        border = AppColors.success;
        bg = AppColors.success.withValues(alpha: 0.10);
      } else if (i == _picked) {
        border = AppColors.coral;
        bg = AppColors.coral.withValues(alpha: 0.10);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _answered ? null : () => _answer(i),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.8),
            ),
            child: Text(_opts[i],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
        ),
      ),
    );
  }
}

/// Kichik dumaloq audio tugma.
class _RoundPlay extends StatelessWidget {
  final String text;
  const _RoundPlay({required this.text});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: Tts.instance.speakingId,
      builder: (context, s, _) => Material(
        color: AppColors.emerald,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Tts.instance.speak(text, id: text),
          child: const SizedBox(
            width: 46, height: 46,
            child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
