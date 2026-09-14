import 'package:flutter/material.dart' hide Text;

import '../content.dart';
import '../main.dart';
import '../mashq/tovush.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/uz_text.dart';

/// Harf chizish — barmoq (yoki sichqoncha) bilan harfni xira andoza
/// ustidan yozish. Motor xotira: harf shakli qo'l harakati orqali
/// yodlanadi; yozish jarayoni o'zi yoqimli (siyoh izi, tovush) — o'quvchi
/// «o'zim yozdim» hissini oladi. Baholash yo'q: chizish erkin, jazosiz.
class HarfChizishEkrani extends StatefulWidget {
  final List<Letter> harflar;

  /// Boshlang'ich harf (dars oynasidan «shu harfni yozib ko'ring»).
  final int boshlanish;
  const HarfChizishEkrani({
    super.key,
    required this.harflar,
    this.boshlanish = 0,
  });

  @override
  State<HarfChizishEkrani> createState() => _HarfChizishEkraniState();
}

class _HarfChizishEkraniState extends State<HarfChizishEkrani> {
  int _i = 0;
  final List<List<Offset>> _chiziqlar = [];
  int _yozilgan = 0; // shu sessiyada «yozdim» deb belgilangan harflar

  Letter get _harf => widget.harflar[_i];

  @override
  void initState() {
    super.initState();
    _i = widget.boshlanish.clamp(0, widget.harflar.length - 1);
    // Birinchi harf ham o'qiladi — keyingilari kabi.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Tts.instance.speak(_harf.nameAr, id: 'chiz-${_harf.ar}'),
    );
  }

  void _boshla(Offset p) => setState(() => _chiziqlar.add([p]));
  void _davom(Offset p) => setState(() => _chiziqlar.last.add(p));

  void _tozala() {
    Haptic.tap();
    setState(_chiziqlar.clear);
  }

  void _keyingi() {
    if (_chiziqlar.isNotEmpty) {
      _yozilgan++;
      Tovush.togri(_yozilgan);
      Haptic.ok();
      progress.hisobQosh(harf: 1);
      // Har 5 harfda +3 ball — chizish ham mehnat.
      if (_yozilgan % 5 == 0) progress.addXp(3);
    }
    setState(() {
      _chiziqlar.clear();
      _i = (_i + 1) % widget.harflar.length;
    });
    Tts.instance.speak(_harf.nameAr, id: 'chiz-${_harf.ar}');
  }

  void _oldingi() {
    setState(() {
      _chiziqlar.clear();
      _i = (_i - 1 + widget.harflar.length) % widget.harflar.length;
    });
    Tts.instance.speak(_harf.nameAr, id: 'chiz-${_harf.ar}');
  }

  @override
  Widget build(BuildContext context) {
    final h = _harf;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harf chizish'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '${_i + 1} / ${widget.harflar.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Nomini eshitish',
                    onPressed: () =>
                        Tts.instance.speak(h.nameAr, id: 'chiz-${h.ar}'),
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.emerald,
                    ),
                  ),
                  Text(
                    '${h.nameUz}  ·  ${h.translit}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Text(
                "Xira harf ustidan barmoq bilan yozing — o'ngdan chapga",
                style: TextStyle(fontSize: 12, color: AppColors.matn3),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final tomon = c.maxWidth.clamp(200.0, 420.0);
                      return Center(
                        child: Container(
                          width: tomon,
                          height: tomon,
                          decoration: BoxDecoration(
                            color: AppColors.karta,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: AppColors.chiziq2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: GestureDetector(
                              onPanStart: (d) => _boshla(d.localPosition),
                              onPanUpdate: (d) => _davom(d.localPosition),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Andoza — xira harf.
                                  Center(
                                    child: Text(
                                      h.ar,
                                      style: AppTheme.arabic(
                                        size: tomon * 0.62,
                                        color: AppColors.emerald.withValues(
                                          alpha: 0.13,
                                        ),
                                        w: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  CustomPaint(
                                    painter: _SiyohPainter(
                                      _chiziqlar,
                                      AppColors.emerald,
                                      tomon * 0.045,
                                    ),
                                  ),
                                  if (_chiziqlar.isEmpty)
                                    Positioned(
                                      bottom: 12,
                                      left: 0,
                                      right: 0,
                                      child: Text(
                                        'Shu yerga yozing',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.matn3,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Oldingi harf',
                      onPressed: _oldingi,
                      icon: const Icon(Icons.chevron_left_rounded, size: 30),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _chiziqlar.isEmpty ? null : _tozala,
                        icon: const Icon(
                          Icons.cleaning_services_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Tozalash',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.coral,
                          side: const BorderSide(color: AppColors.coral),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _keyingi,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _chiziqlar.isEmpty ? 'Keyingi' : 'Yozdim!',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_yozilgan > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Bugun yozildi: $_yozilgan ta harf',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.matn2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Siyoh izi — yumaloq uchli, silliq chiziqlar.
class _SiyohPainter extends CustomPainter {
  final List<List<Offset>> chiziqlar;
  final Color rang;
  final double qalinlik;
  _SiyohPainter(this.chiziqlar, this.rang, this.qalinlik);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = rang
      ..strokeWidth = qalinlik
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final ch in chiziqlar) {
      if (ch.length == 1) {
        canvas.drawCircle(ch.first, qalinlik / 2, Paint()..color = rang);
        continue;
      }
      final path = Path()..moveTo(ch.first.dx, ch.first.dy);
      for (var i = 1; i < ch.length; i++) {
        path.lineTo(ch[i].dx, ch[i].dy);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_SiyohPainter old) => true;
}
