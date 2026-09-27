import 'dart:async';

import 'package:flutter/material.dart' hide Text;

import '../main.dart';
import '../mashq/element.dart';
import '../mnemonika/reja.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/uz_text.dart';

/// ILGAK MASHQI — mnemonikani amalda bajartiradi.
///
/// 1-bosqich (kodlash): har so'z alohida — eshitiladi, o'qilishi,
/// tovushdosh tanish so'z (ilgak) va sahna beriladi; o'quvchi 5 soniya
/// ko'zini yumib sahnani tasavvur qiladi.
/// 2-bosqich (eslash): o'zbekchasi va ilgagi ko'rsatiladi, arabchasi
/// yashirin — o'quvchi eslaydi, keyin ochib o'zini tekshiradi.
/// Eslay olmagan so'z navbat oxiriga qaytadi.
class IlgakMashqi extends StatefulWidget {
  final List<MashqElement> sozlar;
  final String sarlavha;
  const IlgakMashqi({super.key, required this.sozlar, required this.sarlavha});

  @override
  State<IlgakMashqi> createState() => _IlgakMashqiState();
}

class _IlgakMashqiState extends State<IlgakMashqi> {
  static const _tasavvurSoniya = 5;

  int _i = 0;
  bool _eslashBosqichi = false;
  late List<MashqElement> _navbat;
  bool _ochildi = false;
  int _togri = 0;
  int _qoldi = _tasavvurSoniya;
  Timer? _t;
  bool _ozimniki = false;
  final _c = TextEditingController();

  List<MashqElement> get s => widget.sozlar;

  @override
  void initState() {
    super.initState();
    _sozniBoshla();
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _sozniBoshla() {
    final e = s[_i];
    _c.text = RejaXotira.instance.ilgaklar[e.kalit] ?? '';
    _ozimniki = RejaXotira.instance.tayyorIlgak(e.ar) == null;
    _qoldi = _tasavvurSoniya;
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _qoldi--);
      if (_qoldi <= 0) t.cancel();
    });
    Tts.instance.speak(e.ovoz, id: e.kalit);
  }

  Future<void> _keyingi() async {
    final e = s[_i];
    final t = _c.text.trim();
    if (t != (RejaXotira.instance.ilgaklar[e.kalit] ?? '')) {
      await RejaXotira.instance.ilgakYoz(e.kalit, t);
    }
    if (_i + 1 < s.length) {
      setState(() => _i++);
      _sozniBoshla();
    } else {
      _t?.cancel();
      setState(() {
        _eslashBosqichi = true;
        _navbat = List.of(s)..shuffle();
        _ochildi = false;
      });
    }
  }

  Future<void> _baho(bool esladi) async {
    final e = _navbat.first;
    await progress.bumpWord(e.kalit, esladi);
    setState(() {
      _navbat.removeAt(0);
      if (esladi) {
        _togri++;
      } else {
        _navbat.add(e); // eslay olmagan — oxirida yana
      }
      _ochildi = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sarlavha)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _eslashBosqichi ? _eslash() : _kodlash(),
        ),
      ),
    );
  }

  Widget _karta(Widget child, {Color? rang}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: rang ?? AppColors.karta,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.chiziq2),
    ),
    child: child,
  );

  Widget _arabcha(MashqElement e, {double size = 44}) => Directionality(
    textDirection: TextDirection.rtl,
    child: Text(
      e.ar,
      textAlign: TextAlign.center,
      style: AppTheme.arabic(size: size, w: FontWeight.w700),
    ),
  );

  // ---------------- 1. Kodlash ----------------

  Widget _kodlash() {
    final e = s[_i];
    final t = RejaXotira.instance.tayyorIlgak(e.ar);
    final tayyor = _qoldi <= 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(
          children: [
            Text(
              '1-bosqich: ilgak va sahna',
              style: TextStyle(color: AppColors.matn2, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '${_i + 1} / ${s.length}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBar(
          value: (_i + 1) / s.length,
          height: 6,
          color: AppColors.gold,
          background: AppColors.gold.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 14),
        _karta(
          Column(
            children: [
              _arabcha(e),
              if (t != null)
                Text(
                  "o'qilishi: ${t.oqilishi}",
                  style: TextStyle(
                    color: AppColors.matn2,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                e.uz,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              IconButton(
                tooltip: 'Yana eshitish',
                onPressed: () => Tts.instance.speak(e.ovoz, id: e.kalit),
                icon: const Icon(Icons.volume_up_rounded),
                color: AppColors.emerald,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (t != null) ...[
          _karta(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔗', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Tovushi  ',
                        style: TextStyle(color: AppColors.ink, fontSize: 15.5),
                      ),
                      Text(
                        '«${t.ilgak}»',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.coral,
                          fontSize: 16.5,
                        ),
                      ),
                      Text(
                        "  ga o'xshaydi",
                        style: TextStyle(color: AppColors.ink, fontSize: 15.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            rang: AppColors.coral.withValues(alpha: 0.07),
          ),
          const SizedBox(height: 8),
          _karta(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎬', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.sahna,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            rang: AppColors.gold.withValues(alpha: 0.09),
          ),
        ],
        const SizedBox(height: 12),
        // Tasavvur taymeri.
        Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 1 - _qoldi / _tasavvurSoniya,
                    strokeWidth: 4,
                    color: AppColors.emerald,
                    backgroundColor: AppColors.emerald.withValues(alpha: 0.12),
                  ),
                  Text(
                    tayyor ? '✔' : '$_qoldi',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tayyor
                    ? 'Sahna ko\'z oldingizda turibdimi? Unda keyingisiga.'
                    : 'Ko\'zingizni yuming va sahnani tasavvur qiling: katta, '
                          'harakatli, ovozi va hidi bilan.',
                style: TextStyle(color: AppColors.matn2, height: 1.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!_ozimniki && t != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _ozimniki = true),
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(
                _c.text.isEmpty
                    ? 'O\'z ilgagimni yozaman (ixtiyoriy)'
                    : 'Mening ilgagim: ${_c.text}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
        else
          TextField(
            controller: _c,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              isDense: true,
              labelText: t == null
                  ? 'Bu so\'zga ilgakni o\'zingiz to\'qing'
                  : 'Mening ilgagim (ixtiyoriy)',
              hintText: 'Tovushi … ga o\'xshaydi; sahna: …',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: tayyor ? _keyingi : null,
          icon: Icon(
            _i + 1 < s.length
                ? Icons.arrow_forward_rounded
                : Icons.psychology_rounded,
          ),
          label: Text(
            _i + 1 < s.length ? 'Keyingi so\'z' : 'Endi eslab ko\'ramiz',
          ),
        ),
      ],
    );
  }

  // ---------------- 2. Eslash ----------------

  Widget _eslash() {
    if (_navbat.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
        children: [
          const Text(
            '🎉',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 10),
          Text(
            "Hammasi ilgak orqali eslandi!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${s.length} ta so'z, birinchi urinishda $_togri ta. Ilgak — "
            "vaqtinchalik ko'prik: bir necha takrordan keyin so'z o'zi "
            "esga tushadi, ilgak kerak bo'lmay qoladi.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.matn2, height: 1.45),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tayyor — keyingi qadamga'),
          ),
        ],
      );
    }
    final e = _navbat.first;
    final t = RejaXotira.instance.tayyorIlgak(e.ar);
    final ozim = RejaXotira.instance.ilgaklar[e.kalit];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          "2-bosqich: ilgak orqali eslang  ·  qoldi ${_navbat.length}",
          style: TextStyle(color: AppColors.matn2, fontSize: 13),
        ),
        const SizedBox(height: 14),
        _karta(
          Column(
            children: [
              Text(
                e.uz,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              if (t != null || (ozim?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 8),
                Text(
                  ozim?.isNotEmpty ?? false
                      ? '🔗 $ozim'
                      : '🔗 ilgak: «${t!.ilgak}»',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.coral, fontSize: 15),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _karta(
          _ochildi
              ? Column(
                  children: [
                    _arabcha(e, size: 40),
                    if (t != null)
                      Text(
                        t.oqilishi,
                        style: TextStyle(
                          color: AppColors.matn2,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                )
              : SizedBox(
                  height: 90,
                  child: Center(
                    child: Text(
                      'Arabchasini xayolan ayting, keyin oching',
                      style: TextStyle(color: AppColors.matn3),
                    ),
                  ),
                ),
          rang: _ochildi ? null : AppColors.cream,
        ),
        const SizedBox(height: 16),
        if (!_ochildi)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              setState(() => _ochildi = true);
              Tts.instance.speak(e.ovoz, id: e.kalit);
            },
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('Ochish va tekshirish'),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _baho(false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Eslolmadim'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _baho(true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Esladim'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
