import 'package:flutter/material.dart';
import '../../arabic.dart';
import '../../content.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import 'sentence_text.dart';
import 'vocab_flow.dart' show AwardXp;

/// Tinglash bosqichi — matn jumlalarini ketma-ket audio orqali eshitish.
class ListenStage extends StatefulWidget {
  final QiroatLesson lesson;
  final VoidCallback onDone;
  final AwardXp award;
  const ListenStage({super.key, required this.lesson, required this.onDone, required this.award});

  @override
  State<ListenStage> createState() => _ListenStageState();
}

class _ListenStageState extends State<ListenStage> {
  late final List<String> _sentences = splitSentences(widget.lesson.reading);
  int _current = -1;
  bool _playingAll = false;
  bool _listened = false;

  @override
  void dispose() {
    Tts.instance.stop();
    super.dispose();
  }

  Future<void> _playAll() async {
    if (_playingAll) {
      setState(() => _playingAll = false);
      await Tts.instance.stop();
      return;
    }
    setState(() => _playingAll = true);
    for (var i = 0; i < _sentences.length; i++) {
      if (!mounted || !_playingAll) break;
      setState(() => _current = i);
      await Tts.instance.speak(_sentences[i], id: 'listen$i');
    }
    if (mounted) {
      setState(() {
        _playingAll = false;
        _current = -1;
        if (!_listened) {
          _listened = true;
          widget.award(3);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Row(
            children: [
              const Text('🎧  Avval tinglang',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15)),
              const Spacer(),
              FilledButton.icon(
                onPressed: _playAll,
                icon: Icon(_playingAll ? Icons.stop_rounded : Icons.play_arrow_rounded),
                label: Text(_playingAll ? 'To\'xtatish' : 'Hammasini tinglash'),
                style: FilledButton.styleFrom(
                  backgroundColor: _playingAll ? AppColors.coral : AppColors.emerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            itemCount: _sentences.length,
            itemBuilder: (context, i) {
              final active = i == _current;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: active ? AppColors.softGreen : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: active ? AppColors.emerald : Colors.black12, width: active ? 1.6 : 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: AppColors.emerald,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Tts.instance.speak(_sentences[i], id: 'listen$i'),
                        child: const SizedBox(
                          width: 40, height: 40,
                          child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(_sentences[i],
                            textAlign: TextAlign.right,
                            style: AppTheme.arabic(size: 23, color: AppColors.ink, w: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _footer() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              if (!_listened) widget.award(3);
              widget.onDone();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('O\'qishga o\'tish', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      );
}

/// O'qish bosqichi — har jumlani tushunish. Bosilgan jumla yashil bo'ladi,
/// har bir so'z bosiladi (ma'no/audio). Progress: N / jami jumla.
class ReadStage extends StatefulWidget {
  final QiroatLesson lesson;
  final VoidCallback onDone;
  final AwardXp award;
  const ReadStage({super.key, required this.lesson, required this.onDone, required this.award});

  @override
  State<ReadStage> createState() => _ReadStageState();
}

class _ReadStageState extends State<ReadStage> {
  late final List<String> _sentences = splitSentences(widget.lesson.reading);
  final Set<int> _done = {};
  bool _awarded = false;

  @override
  void dispose() {
    Tts.instance.stop();
    super.dispose();
  }

  void _toggle(int i) {
    setState(() {
      if (!_done.add(i)) _done.remove(i);
    });
    if (_done.length == _sentences.length && !_awarded) {
      _awarded = true;
      widget.award(5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _done.length == _sentences.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('📖  O\'qing va tushuning',
                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15)),
                  const Spacer(),
                  Text('${_done.length} / ${_sentences.length} jumla',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.emerald)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _sentences.isEmpty ? 1 : _done.length / _sentences.length,
                  minHeight: 8,
                  backgroundColor: AppColors.softGreen,
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                ),
              ),
              const SizedBox(height: 4),
              const Text('So\'zga bosib — ma\'nosini ko\'ring. Jumlani tushunsangiz ✓ bosing.',
                  style: TextStyle(fontSize: 11.5, color: Colors.black45)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            itemCount: _sentences.length,
            itemBuilder: (context, i) {
              final done = _done.contains(i);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                decoration: BoxDecoration(
                  color: done ? const Color(0xFFDDF1E4) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: done ? AppColors.success : Colors.black12, width: done ? 1.4 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SentenceText(
                      sentence: _sentences[i],
                      vocab: widget.lesson.vocab,
                      reading: widget.lesson.reading,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Tts.instance.speak(_sentences[i], id: 'read$i'),
                          icon: const Icon(Icons.volume_up_rounded, color: AppColors.emerald),
                          visualDensity: VisualDensity.compact,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _toggle(i),
                          icon: Icon(done ? Icons.check_circle : Icons.check_circle_outline,
                              color: done ? AppColors.success : Colors.black38, size: 20),
                          label: Text(done ? 'Tushundim' : 'Tushundim',
                              style: TextStyle(
                                  color: done ? AppColors.success : Colors.black54,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: all
                  ? widget.onDone
                  : () {
                      // barcha jumlalarni tushunilgan deb belgilab davom etsa ham bo'ladi
                      setState(() => _done.addAll(List.generate(_sentences.length, (i) => i)));
                      if (!_awarded) {
                        _awarded = true;
                        widget.award(5);
                      }
                      widget.onDone();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: all ? AppColors.emerald : AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(all ? 'Savollarga o\'tish' : 'Barchasini tushundim',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}
