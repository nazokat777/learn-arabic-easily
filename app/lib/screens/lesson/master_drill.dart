import 'dart:math';
import 'package:flutter/material.dart';
import '../../arabic.dart';
import '../../content.dart';
import '../../main.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import 'word_sheet.dart';

/// «Master Drill» — so'zni CHINDAN yodlatadigan ko'p usulli mashq.
/// Har bir so'z 6 xil usuldan o'tishi shart (bitta usulda bir-ikki to'g'ri javob
/// yetarli emas). Usullar: tanish, teskari, eshit, top, harflardan tuz, gap tuz.
/// Daraja saqlanadi (offline), sessiyalar aro to'planadi.
class MasterDrill extends StatefulWidget {
  final QiroatLesson lesson;
  const MasterDrill({super.key, required this.lesson});

  @override
  State<MasterDrill> createState() => _MasterDrillState();
}

const List<(IconData, String, String)> _modeMeta = [
  (Icons.translate_rounded, 'Tanish', 'Bu so\'z nima degani?'),
  (Icons.swap_horiz_rounded, 'Teskari', 'Qaysi so\'z shu ma\'noda?'),
  (Icons.headphones_rounded, 'Eshit va top', 'Eshiting va ma\'nosini toping'),
  (Icons.grid_view_rounded, 'Top', 'So\'zni boshqalar ichidan toping'),
  (Icons.abc_rounded, 'Harflardan tuz', 'Harflarni tartib bilan bosib so\'zni yozing'),
  (Icons.notes_rounded, 'Gap tuz', 'So\'zlarni tartiblab jumla tuzing'),
];

class _MasterDrillState extends State<MasterDrill> {
  final _rnd = Random();
  late List<QiroatVocab> _pool;
  late List<QiroatVocab> _queue;
  final Map<String, List<int>> _reqCache = {}; // kerakli usullar (keshlangan)
  int _xpEarned = 0;

  QiroatVocab? _word;
  int _mode = 0;

  // MCQ holati
  List<String> _options = [];
  int _correct = 0;
  int? _picked;
  bool _answered = false;

  // Tartiblash (harflar/gap) holati
  List<String> _tiles = [];
  List<String> _target = [];
  final List<int> _built = [];
  bool? _arrangeOk;

  String _key(QiroatVocab v) => '${widget.lesson.completionId}::${v.ar}';
  String _head(QiroatVocab v) => splitForms(v.ar).first;

  @override
  void initState() {
    super.initState();
    final seen = <String>{};
    _pool = [];
    for (final v in widget.lesson.vocab) {
      if (v.ar.trim().isEmpty || v.uz.trim().isEmpty) continue;
      if (seen.add(v.uz)) _pool.add(v);
    }
    for (final v in _pool) {
      _reqCache[_key(v)] = _computeRequiredModes(v);
    }
    _buildQueue();
    _next();
  }

  @override
  void dispose() {
    Tts.instance.stop();
    super.dispose();
  }

  /// So'z uchun kerakli usullar (ba'zi usullar ba'zi so'zlarga to'g'ri kelmaydi).
  List<int> _requiredModes(QiroatVocab v) => _reqCache[_key(v)] ?? _computeRequiredModes(v);

  List<int> _computeRequiredModes(QiroatVocab v) {
    final modes = [0, 1, 2, 3];
    final letters = stripDiacritics(_head(v));
    if (!letters.contains(' ') && letters.length >= 2 && letters.length <= 7) {
      modes.add(4); // harflardan tuz
    }
    if (_example(v) != null) modes.add(5); // gap tuz
    return modes;
  }

  int _requiredMask(QiroatVocab v) {
    int m = 0;
    for (final i in _requiredModes(v)) {
      m |= (1 << i);
    }
    return m;
  }

  bool _mastered(QiroatVocab v) {
    final req = _requiredMask(v);
    return (progress.wordModeMask(_key(v)) & req) == req;
  }

  int get _doneCount => _pool.where(_mastered).length;

  void _buildQueue() {
    _queue = _pool.where((v) => !_mastered(v)).toList()..shuffle(_rnd);
  }

  /// So'z uchun keyingi (hali o'tilmagan) usulni tanlaydi.
  int _nextMode(QiroatVocab v) {
    for (final i in _requiredModes(v)) {
      if (!progress.isModeDone(_key(v), i)) return i;
    }
    return _requiredModes(v).first;
  }

  String? _example(QiroatVocab v) {
    final needle = stripDiacritics(_head(v));
    if (needle.length < 3) return null;
    for (final s in splitSentences(widget.lesson.reading)) {
      if (stripDiacritics(s).contains(needle)) {
        final words = s.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
        if (words.length >= 3 && words.length <= 10) return s;
      }
    }
    return null;
  }

  void _next() {
    if (_queue.isEmpty) {
      _word = null;
      return;
    }
    final v = _queue.first;
    _word = v;
    _mode = _nextMode(v);
    _picked = null;
    _answered = false;
    _arrangeOk = null;
    _built.clear();
    if (_mode <= 3) {
      _buildMcq(v, _mode);
    } else if (_mode == 4) {
      _buildLetters(v);
    } else {
      _buildSentence(v);
    }
    // Eshitish usullarida avtomatik o'qib beramiz
    if (_mode == 0 || _mode == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Tts.instance.speak(_head(v), id: 'q'));
    }
  }

  void _buildMcq(QiroatVocab word, int mode) {
    final arToUz = mode == 0 || mode == 2; // javob = o'zbekcha
    final correctVal = arToUz ? word.uz : _head(word);
    final distract = _pool
        .where((v) => v != word)
        .map((v) => arToUz ? v.uz : _head(v))
        .where((s) => s != correctVal)
        .toSet()
        .toList()
      ..shuffle(_rnd);
    final count = mode == 3 ? 5 : 3; // «Top» — 6 tilelik grid
    _options = <String>[correctVal, ...distract.take(count)]..shuffle(_rnd);
    _correct = _options.indexOf(correctVal);
  }

  void _buildLetters(QiroatVocab v) {
    final letters = stripDiacritics(_head(v)).split('').where((c) => c.trim().isNotEmpty).toList();
    _target = letters;
    _tiles = [...letters]..shuffle(_rnd);
    // Aralashuv bir xil chiqmasligi uchun (qisqa so'zlar)
    if (_tiles.length > 1 && _tiles.join() == _target.join()) {
      _tiles = _tiles.reversed.toList();
    }
  }

  void _buildSentence(QiroatVocab v) {
    final s = _example(v)!;
    final words = s.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
    _target = words;
    _tiles = [...words]..shuffle(_rnd);
    if (_tiles.join(' ') == _target.join(' ')) _tiles = _tiles.reversed.toList();
  }

  // --- Javob berish ---

  Future<void> _answerMcq(int i) async {
    if (_answered) return;
    final v = _word!;
    final ok = i == _correct;
    setState(() {
      _picked = i;
      _answered = true;
    });
    if (ok) {
      await progress.addXp(2);
      _xpEarned += 2;
    }
    await progress.markMode(_key(v), _mode, ok);
    await _afterAnswer(v, ok);
  }

  Future<void> _checkArrange() async {
    if (_arrangeOk != null) return;
    final v = _word!;
    final built = _built.map((i) => _tiles[i]).toList();
    final sep = _mode == 5 ? ' ' : '';
    final ok = built.join(sep) == _target.join(sep);
    setState(() => _arrangeOk = ok);
    if (ok) {
      await progress.addXp(3);
      _xpEarned += 3;
    }
    await progress.markMode(_key(v), _mode, ok);
    await _afterAnswer(v, ok);
  }

  Future<void> _afterAnswer(QiroatVocab v, bool ok) async {
    final justMastered = ok && _mastered(v);
    if (justMastered) {
      await progress.addXp(5);
      _xpEarned += 5;
    }
    if (mounted) setState(() {});
    Future.delayed(Duration(milliseconds: ok ? 750 : 1400), () async {
      if (!mounted) return;
      // navbatni yangilaymiz
      if (_mastered(v)) {
        _queue.remove(v);
      } else if (_queue.isNotEmpty) {
        // o'sha so'zni oxiriga surib, boshqasini ko'rsatamiz
        _queue.removeAt(0);
        _queue.add(v);
      }
      setState(_next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lesson.num}-dars — chuqur yodlash'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text('⭐ $_xpEarned',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold)),
            ),
          ),
        ],
      ),
      body: SafeArea(child: _word == null ? _doneView() : _questionView()),
    );
  }

  Widget _doneView() {
    final all = _doneCount >= _pool.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Zo\'r natija!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.emerald)),
            const SizedBox(height: 8),
            Text(
              all
                  ? 'Bu darsning barcha ${_pool.length} so\'zi 6 xil usulda chuqur yodlandi! +$_xpEarned XP'
                  : 'Yodlangan: $_doneCount / ${_pool.length} so\'z. +$_xpEarned XP',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.ink, height: 1.4),
            ),
            const SizedBox(height: 26),
            if (!all)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => setState(() {
                    _buildQueue();
                    _next();
                  }),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Davom etish', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            if (!all) const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: AppColors.emerald),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Darsga qaytish',
                    style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionView() {
    final v = _word!;
    final total = _pool.length;
    final maskSum = _pool.fold<int>(0, (s, w) => s + progress.masterCount(_key(w)));
    final maxSum = _pool.fold<int>(0, (s, w) => s + _requiredModes(w).length);
    final value = maxSum == 0 ? 0.0 : maskSum / maxSum;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value, minHeight: 12,
              backgroundColor: AppColors.softGreen,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Yodlangan: $_doneCount / $total so\'z',
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
              _modeChip(),
            ],
          ),
        ),
        // shu so'zning usul-nuqtalari
        _modeDots(v),
        const Spacer(),
        Text(_modeMeta[_mode].$3, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 14),
        Expanded(flex: 6, child: _modeBody(v)),
        _feedbackBar(),
      ],
    );
  }

  Widget _modeChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_modeMeta[_mode].$1, size: 14, color: AppColors.emerald),
            const SizedBox(width: 5),
            Text('${_mode + 1}/6 · ${_modeMeta[_mode].$2}',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.emerald)),
          ],
        ),
      );

  Widget _modeDots(QiroatVocab v) {
    final req = _requiredModes(v).toSet();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (i) {
          final required = req.contains(i);
          final done = progress.isModeDone(_key(v), i);
          final cur = i == _mode;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: !required ? Colors.transparent : (done ? AppColors.success : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(
                color: !required ? Colors.black12 : (cur ? AppColors.emerald : (done ? AppColors.success : Colors.black26)),
                width: cur ? 2 : 1.4,
              ),
            ),
            child: Icon(_modeMeta[i].$1,
                size: 13, color: !required ? Colors.black12 : (done ? Colors.white : Colors.black38)),
          );
        }),
      ),
    );
  }

  Widget _modeBody(QiroatVocab v) {
    switch (_mode) {
      case 0:
        return _mcqBody(v, prompt: _arWord(_head(v), play: true), arabicOptions: false);
      case 1:
        return _mcqBody(v, prompt: _uzWord(v.uz), arabicOptions: true);
      case 2:
        return _mcqBody(v, prompt: _listenPrompt(v), arabicOptions: false);
      case 3:
        return _findBody(v);
      case 4:
      case 5:
        return _arrangeBody(v);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- MCQ ---
  Widget _mcqBody(QiroatVocab v, {required Widget prompt, required bool arabicOptions}) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: prompt,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            children: List.generate(_options.length, (i) => _optTile(i, arabicOptions)),
          ),
        ),
      ],
    );
  }

  Widget _findBody(QiroatVocab v) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: _uzWord(v.uz),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.6,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            children: List.generate(_options.length, (i) => _optTile(i, true, grid: true)),
          ),
        ),
      ],
    );
  }

  Widget _arWord(String ar, {bool play = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(ar,
                  textAlign: TextAlign.center,
                  style: AppTheme.arabic(size: 40, color: AppColors.emerald)),
            ),
          ),
          if (play) ...[
            const SizedBox(width: 8),
            _playBtn(ar),
          ],
        ],
      );

  Widget _uzWord(String uz) => Text(uz,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.emerald));

  Widget _listenPrompt(QiroatVocab v) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _bigPlay(_head(v)),
          const SizedBox(height: 8),
          const Text('Tinglang va ma\'nosini tanlang',
              style: TextStyle(fontSize: 13, color: Colors.black45)),
        ],
      );

  Widget _optTile(int i, bool arabic, {bool grid = false}) {
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
    final child = arabic
        ? Directionality(
            textDirection: TextDirection.rtl,
            child: Text(_options[i],
                textAlign: TextAlign.center,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppTheme.arabic(size: grid ? 22 : 24, color: AppColors.ink)))
        : Text(_options[i],
            textAlign: grid ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink));
    final tile = Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _answered ? null : () => _answerMcq(i),
        child: Container(
          width: double.infinity,
          alignment: grid ? Alignment.center : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.8),
          ),
          child: child,
        ),
      ),
    );
    return grid ? tile : Padding(padding: const EdgeInsets.only(bottom: 10), child: tile);
  }

  // --- Tartiblash (harflar / gap) ---
  Widget _arrangeBody(QiroatVocab v) {
    final built = _built.map((i) => _tiles[i]).toList();
    return Column(
      children: [
        // Yig'ilgan javob
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _arrangeOk == null ? Colors.black12 : (_arrangeOk! ? AppColors.success : AppColors.coral),
              width: 1.6,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6, runSpacing: 6,
              children: built.isEmpty
                  ? [const Text('Bu yerga tartiblang', style: TextStyle(color: Colors.black26))]
                  : List.generate(built.length, (k) => _chip(built[k], onTap: _answered0() ? null : () {
                        setState(() => _built.removeAt(k));
                      })),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(_mode == 4 ? 'Harflarni tartib bilan bosing' : 'So\'zlarni tartib bilan bosing',
            style: const TextStyle(fontSize: 12, color: Colors.black38)),
        const SizedBox(height: 8),
        // Tanlanadigan tokenlar
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8, runSpacing: 8,
                children: List.generate(_tiles.length, (i) {
                  final used = _built.contains(i);
                  return _chip(_tiles[i],
                      faded: used,
                      onTap: (used || _arrangeOk != null) ? null : () => setState(() => _built.add(i)));
                }),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: (_built.isEmpty || _arrangeOk != null) ? null : () => setState(_built.clear),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tozalash'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: (_built.length != _target.length || _arrangeOk != null) ? null : _checkArrange,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tekshirish', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _answered0() => _arrangeOk != null;

  Widget _chip(String text, {VoidCallback? onTap, bool faded = false}) {
    final isSentence = _mode == 5;
    return Opacity(
      opacity: faded ? 0.3 : 1,
      child: Material(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isSentence ? 12 : 14, vertical: isSentence ? 8 : 10),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(text,
                  style: AppTheme.arabic(size: isSentence ? 20 : 26, color: AppColors.emeraldDark)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _playBtn(String text) => ValueListenableBuilder<String?>(
        valueListenable: Tts.instance.speakingId,
        builder: (context, s, _) => Material(
          color: AppColors.emerald,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Tts.instance.speak(text, id: text),
            child: const SizedBox(
                width: 42, height: 42, child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 22)),
          ),
        ),
      );

  Widget _bigPlay(String text) => ValueListenableBuilder<String?>(
        valueListenable: Tts.instance.speakingId,
        builder: (context, s, _) => Material(
          color: AppColors.emerald,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Tts.instance.speak(text, id: text),
            child: const SizedBox(
                width: 84, height: 84, child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 44)),
          ),
        ),
      );

  Widget _feedbackBar() {
    final show = _answered || _arrangeOk != null;
    if (!show) return const SizedBox(height: 58);
    final v = _word!;
    final ok = _mode <= 3 ? _picked == _correct : (_arrangeOk ?? false);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 58),
      alignment: Alignment.centerLeft,
      color: (ok ? AppColors.success : AppColors.coral).withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ok
                  ? (_mastered(v) ? '🏆 «${_head(v)}» to\'liq yodlandi!' : '✅ To\'g\'ri!')
                  : '❌ To\'g\'ri javob: ${_mode <= 3 ? _options[_correct] : _target.join(_mode == 5 ? ' ' : '')}',
              style: TextStyle(fontWeight: FontWeight.w800, color: ok ? AppColors.success : AppColors.coral),
            ),
          ),
          IconButton(
            onPressed: () => showWordSheet(context, v, reading: widget.lesson.reading),
            icon: const Icon(Icons.info_outline, color: AppColors.emerald),
            tooltip: 'Grammatik tahlil',
          ),
        ],
      ),
    );
  }
}
