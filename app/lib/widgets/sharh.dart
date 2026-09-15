import 'package:flutter/material.dart' hide Text;

import '../content.dart';
import '../main.dart';
import '../mashq/mukofot.dart';
import '../mashq/tovush.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import 'aralash_matn.dart';
import 'uz_text.dart';

/// «Sharh» — darsning ODDIY TILDA izohi. Kitob matni EMAS: kitob qoidasi
/// yuqorida o'z holicha turadi, bu esa ustozning og'zaki tushuntirishi
/// kabi — misol, taqqos, «nega shunday» va tez-tez adashiladigan joylar.
/// Yopiq bo'lmasin: birinchi xatboshi ko'rinib turadi, qolgani ochiladi.
class SharhBolimi extends StatefulWidget {
  final String darsId;
  const SharhBolimi({super.key, required this.darsId});

  @override
  State<SharhBolimi> createState() => _SharhBolimiState();
}

class _SharhBolimiState extends State<SharhBolimi> {
  bool _ochiq = false;

  @override
  Widget build(BuildContext context) {
    final s = repo.sharhlar[widget.darsId];
    if (s == null || s.sharh.isEmpty) return const SizedBox.shrink();
    final korinadi = _ochiq ? s.sharh : s.sharh.take(1).toList();
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.indigo.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_rounded,
                size: 18,
                color: AppColors.indigo,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sharh — oddiy tilda',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'izoh · kitob matni emas',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.indigo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final (i, p) in korinadi.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            AralashMatn(
              p,
              uslub: TextStyle(
                fontSize: 14.5,
                height: 1.55,
                color: AppColors.ink,
              ),
              arabchaOlchami: 21,
            ),
          ],
          if (s.sharh.length > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Haptic.tap();
                  setState(() => _ochiq = !_ochiq);
                },
                icon: Icon(
                  _ochiq
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                ),
                label: Text(
                  _ochiq ? 'Qisqartirish' : 'Batafsil tushuntirish',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(44, 36),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// «Qoidani tekshiring» — darsdan keyin QOIDA bo'yicha interaktiv savollar
/// («…bo'lsa nima bo'ladi?», «jazm holatida …?»). Tarjima emas, tushunish.
/// Har savol bir marta javob beriladi: to'g'ri — +2 ball, izoh; noto'g'ri —
/// to'g'risi ko'rsatiladi va NEGA — izoh. Oxirida natija; «Qayta» bilan
/// aralashtirib yana. Javoblar kunlik hisobga kiradi (bumpWord).
class QoidaSavollari extends StatefulWidget {
  final String darsId;
  const QoidaSavollari({super.key, required this.darsId});

  @override
  State<QoidaSavollari> createState() => _QoidaSavollariState();
}

class _QoidaSavollariState extends State<QoidaSavollari> {
  final Map<int, int> _javob = {}; // savol → tanlangan variant
  int _portlash = 0;

  List<QoidaSavol> get _savollar =>
      repo.sharhlar[widget.darsId]?.savollar ?? const [];

  Future<void> _tanla(int i, int v) async {
    if (_javob.containsKey(i)) return;
    final s = _savollar[i];
    final ok = v == s.togri;
    ok ? Haptic.ok() : Haptic.wrong();
    ok ? Tovush.togri(1) : Tovush.xato();
    setState(() {
      _javob[i] = v;
      if (ok) _portlash++;
    });
    if (ok) progress.addXp(2);
    await progress.bumpWord('${widget.darsId}::qoida-$i', ok);
    if (_javob.length == _savollar.length &&
        _javob.entries.every((e) => _savollar[e.key].togri == e.value)) {
      Tovush.daraja();
    }
  }

  @override
  Widget build(BuildContext context) {
    final savollar = _savollar;
    if (savollar.isEmpty) return const SizedBox.shrink();
    final tugadi = _javob.length == savollar.length;
    final togri = _javob.entries
        .where((e) => savollar[e.key].togri == e.value)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.quiz_rounded, size: 18, color: AppColors.emerald),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Qoidani tekshiring',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              '${_javob.length} / ${savollar.length}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: tugadi ? AppColors.success : AppColors.matn3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tarjima emas — tushunish: qoidani vaziyatga qo\'llang.',
          style: TextStyle(fontSize: 12, color: AppColors.matn3),
        ),
        const SizedBox(height: 10),
        for (final (i, s) in savollar.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Savol(
              raqam: i + 1,
              savol: s,
              tanlangan: _javob[i],
              onTanla: (v) => _tanla(i, v),
            ),
          ),
        if (tugadi)
          Portlash(
            trigger: _portlash,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color:
                    (togri == savollar.length
                            ? AppColors.success
                            : AppColors.gold)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    togri == savollar.length
                        ? Icons.emoji_events_rounded
                        : Icons.lightbulb_rounded,
                    color: togri == savollar.length
                        ? AppColors.success
                        : AppColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      togri == savollar.length
                          ? 'Qoidani to\'liq tushundingiz — '
                                '$togri / ${savollar.length}!'
                          : '$togri / ${savollar.length} to\'g\'ri. '
                                'Izohlarni o\'qib, yana urinib ko\'ring.',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Haptic.tap();
                      setState(_javob.clear);
                    },
                    child: const Text(
                      'Qayta',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Savol extends StatelessWidget {
  final int raqam;
  final QoidaSavol savol;
  final int? tanlangan;
  final ValueChanged<int> onTanla;
  const _Savol({
    required this.raqam,
    required this.savol,
    required this.tanlangan,
    required this.onTanla,
  });

  @override
  Widget build(BuildContext context) {
    final javobBerildi = tanlangan != null;
    final togri = tanlangan == savol.togri;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.karta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !javobBerildi
              ? AppColors.chiziq
              : (togri ? AppColors.success : AppColors.coral).withValues(
                  alpha: 0.6,
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$raqam',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: AppColors.emerald,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AralashMatn(
                  savol.savol,
                  uslub: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: AppColors.ink,
                  ),
                  arabchaOlchami: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final (v, matn) in savol.variantlar.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _Variant(
                matn: matn,
                holat: !javobBerildi
                    ? _Holat.oddiy
                    : v == savol.togri
                    ? _Holat.togri
                    : (v == tanlangan ? _Holat.xato : _Holat.xira),
                onTap: javobBerildi ? null : () => onTanla(v),
              ),
            ),
          if (javobBerildi && savol.izoh.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: (togri ? AppColors.success : AppColors.indigo)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AralashMatn(
                (togri ? 'To\'g\'ri. ' : 'Izoh: ') + savol.izoh,
                uslub: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.ink,
                ),
                arabchaOlchami: 19,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _Holat { oddiy, togri, xato, xira }

class _Variant extends StatelessWidget {
  final String matn;
  final _Holat holat;
  final VoidCallback? onTap;
  const _Variant({required this.matn, required this.holat, this.onTap});

  @override
  Widget build(BuildContext context) {
    final rang = switch (holat) {
      _Holat.togri => AppColors.success,
      _Holat.xato => AppColors.coral,
      _ => AppColors.chiziq2,
    };
    return Shake(
      trigger: holat == _Holat.xato ? matn : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: holat == _Holat.xira ? 0.5 : 1,
        child: Material(
          color: holat == _Holat.togri
              ? AppColors.success.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: rang,
                  width: holat == _Holat.oddiy ? 1 : 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    switch (holat) {
                      _Holat.togri => Icons.check_circle_rounded,
                      _Holat.xato => Icons.cancel_rounded,
                      _ => Icons.circle_outlined,
                    },
                    size: 18,
                    color: holat == _Holat.oddiy ? AppColors.matn3 : rang,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AralashMatn(
                      matn,
                      bosiladi: false,
                      uslub: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: AppColors.ink,
                      ),
                      arabchaOlchami: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
