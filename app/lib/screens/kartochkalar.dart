import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../main.dart';
import '../mashq/bank.dart';
import '../mashq/element.dart';
import '../mashq/mukofot.dart' show BugunChizigi;
import '../mashq/tovush.dart';
import '../rasm.dart';
import 'nishonlar_ekrani.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import '../widgets/uz_text.dart';

/// Kartochkalar — svayp bilan tez takror: arabcha tomon, bosilsa ag'dariladi
/// (ma'nosi), o'ngga surilsa «bildim», chapga — «bilmadim» (karta oxiriga
/// qaytadi). Qo'l harakati + darhol natija — eng tez «oqim» rejimi;
/// eslash vaqti kelgan so'zlar uchun oraliqli takrorning qulay shakli.
void kartochkalarniOch(BuildContext context) {
  var elementlar = MashqBank.kalitlarBoyicha(
    progress.eslashKerakKalitlar.toSet(),
  );
  if (elementlar.length < 5) {
    final hammasi = MashqBank.hammasi();
    final tanish = hammasi
        .where((e) => progress.wordMastery(e.kalit) > 0)
        .toList();
    elementlar = [
      ...elementlar,
      ...(tanish.length >= 5 ? tanish : hammasi.take(40).toList())..shuffle(),
    ];
  }
  // Takrorlanmasin, 15 tadan oshmasin.
  final korilgan = <String>{};
  final tanlangan = <MashqElement>[];
  for (final e in elementlar) {
    if (korilgan.add(e.kalit)) tanlangan.add(e);
    if (tanlangan.length >= 15) break;
  }
  if (tanlangan.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => KartochkalarEkrani(elementlar: tanlangan),
    ),
  );
}

class KartochkalarEkrani extends StatefulWidget {
  final List<MashqElement> elementlar;
  const KartochkalarEkrani({super.key, required this.elementlar});

  @override
  State<KartochkalarEkrani> createState() => _KartochkalarEkraniState();
}

class _KartochkalarEkraniState extends State<KartochkalarEkrani>
    with SingleTickerProviderStateMixin {
  late final List<MashqElement> _navbat = List.of(widget.elementlar);
  final List<MashqElement> _bilmadimlar = [];
  int _bildim = 0;
  int _bilmadim = 0;
  int _ball = 0;
  bool _agdarilgan = false;
  double _dx = 0;
  bool _tugadi = false;

  static const _chegara = 90.0;

  MashqElement get _joriy => _navbat.first;

  @override
  void initState() {
    super.initState();
    _oqi();
  }

  /// Joriy karta ochilganda so'z o'qiladi — ko'rish + eshitish.
  void _oqi() {
    final e = _navbat.isEmpty ? null : _navbat.first;
    if (e != null && e.ovoz.isNotEmpty) {
      Tts.instance.speak(e.ovoz, id: e.kalit);
    }
  }

  void _yechim(bool ok) {
    final e = _joriy;
    Haptic.tap();
    if (ok) {
      _bildim++;
      _ball += 1;
      progress.bumpWord(e.kalit, true);
      progress.addXp(1);
      progress.hisobQosh(karta: 1);
      Tovush.togri(_bildim);
    } else {
      _bilmadim++;
      progress.bumpWord(e.kalit, false);
      _bilmadimlar.add(e);
    }
    setState(() {
      _navbat.removeAt(0);
      _dx = 0;
      _agdarilgan = false;
      if (_navbat.isEmpty) _tugadi = true;
    });
    if (_tugadi) {
      _nishonlarniTekshir();
    } else {
      _oqi();
    }
  }

  Future<void> _nishonlarniTekshir() async {
    final yangi = await progress.yangiNishonlar();
    if (yangi.isNotEmpty && mounted) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) await nishonOynasi(context, yangi);
    }
  }

  void _yanaTakror() {
    setState(() {
      _navbat.addAll(_bilmadimlar);
      _bilmadimlar.clear();
      _bilmadim = 0;
      _bildim = 0;
      _tugadi = false;
      _agdarilgan = false;
      _dx = 0;
    });
    _oqi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartochkalar'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: XpChip(value: _ball),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _tugadi ? _yakun() : _oyin(),
        ),
      ),
    );
  }

  Widget _oyin() {
    final e = _joriy;
    final jami = widget.elementlar.length;
    final ochilgan = jami - _navbat.length + _bilmadimlar.length;
    final rasm = Rasm.topish(e.uz);
    // Surilish: rang va burilish — qaror qilinayotgani sezilsin.
    final ulush = (_dx / _chegara).clamp(-1.0, 1.0);
    final rang = ulush > 0
        ? AppColors.success
        : (ulush < 0 ? AppColors.coral : AppColors.chiziq2);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Text(
                '${ochilgan.clamp(0, jami)} / $jami',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.indigo,
                ),
              ),
              const Spacer(),
              Icon(Icons.check_rounded, size: 16, color: AppColors.success),
              Text(
                ' $_bildim   ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
              Icon(Icons.replay_rounded, size: 16, color: AppColors.coral),
              Text(
                ' $_bilmadim',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.coral,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedBar(
            value: jami == 0 ? 0 : (jami - _navbat.length) / jami,
            height: 6,
            color: AppColors.indigo,
            background: AppColors.indigo.withValues(alpha: 0.12),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () {
                Haptic.tap();
                setState(() => _agdarilgan = !_agdarilgan);
                // Ma'nosi ochilganda so'z yana bir bor eshitiladi.
                if (_agdarilgan && e.ovoz.isNotEmpty) {
                  Tts.instance.speak(e.ovoz, id: e.kalit);
                }
              },
              onHorizontalDragUpdate: (d) =>
                  setState(() => _dx = (_dx + d.delta.dx).clamp(-220.0, 220.0)),
              onHorizontalDragEnd: (_) {
                if (_dx > _chegara) {
                  _yechim(true);
                } else if (_dx < -_chegara) {
                  _yechim(false);
                } else {
                  setState(() => _dx = 0);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                transform: Matrix4.identity()
                  ..translateByDouble(_dx, 0, 0, 1)
                  ..rotateZ(ulush * 0.06),
                transformAlignment: Alignment.center,
                width: 320,
                height: 380,
                child: FlipCard(
                  flipped: _agdarilgan,
                  front: _yuz(
                    rang: rang,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (rasm != null)
                          Text(rasm, style: const TextStyle(fontSize: 44)),
                        const SizedBox(height: 10),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            e.ar,
                            textAlign: TextAlign.center,
                            style: AppTheme.arabic(
                              size: 40,
                              color: AppColors.ink,
                              w: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (e.ovoz.isNotEmpty)
                          IconButton(
                            tooltip: 'Tinglash',
                            onPressed: () =>
                                Tts.instance.speak(e.ovoz, id: e.kalit),
                            icon: const Icon(
                              Icons.volume_up_rounded,
                              color: AppColors.emerald,
                              size: 30,
                            ),
                          ),
                        Text(
                          "Bosing — ma'nosi",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.matn3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  back: _yuz(
                    rang: rang,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          e.uz,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            e.ar,
                            style: AppTheme.arabic(
                              size: 24,
                              color: AppColors.matn2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _yechim(false),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text(
                    'Bilmadim',
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
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _yechim(true),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'Bildim',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            "O'ngga suring — bildim, chapga — bilmadim",
            style: TextStyle(fontSize: 11.5, color: AppColors.matn3),
          ),
        ),
      ],
    );
  }

  Widget _yuz({required Color rang, required Widget child}) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.karta,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: rang, width: 2),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.10),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: child,
  );

  Widget _yakun() {
    final jami = widget.elementlar.length;
    final mukammal = _bilmadimlar.isEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      child: Column(
        children: [
          Reveal(
            fromScale: 0.6,
            child: GlowRing(
              size: 128,
              color: mukammal ? AppColors.gold : AppColors.indigo,
              child: Float(
                amplitude: 4,
                child: Icon(
                  mukammal ? Icons.emoji_events_rounded : Icons.style_rounded,
                  size: 60,
                  color: mukammal ? AppColors.gold : AppColors.indigo,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            mukammal ? 'Hammasini bildingiz!' : 'Kartochkalar tugadi',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$jami ta karta  ·  $_bildim bildim  ·  +$_ball ball',
            style: TextStyle(color: AppColors.matn2, fontSize: 14),
          ),
          const SizedBox(height: 18),
          const BugunChizigi(),
          const SizedBox(height: 22),
          if (!mukammal) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _yanaTakror,
                icon: const Icon(Icons.replay_rounded),
                label: Text(
                  'Bilmaganlarni yana (${_bilmadimlar.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.indigo,
                side: const BorderSide(color: AppColors.indigo),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Tayyor',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Testlar uchun: ekranga tasodifiy tanlov emas, berilgan ro'yxat.
List<MashqElement> kartochkaHavzasi(Random rnd, int soni) {
  final hammasi = MashqBank.hammasi()..shuffle(rnd);
  return hammasi.take(soni).toList();
}
