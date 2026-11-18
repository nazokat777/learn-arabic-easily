import 'package:flutter/material.dart' hide Text;

import '../content.dart';
import '../harflab.dart';
import '../main.dart';
import '../mashq/bank.dart';
import '../mashq/element.dart';
import '../mashq/mashq_ekran.dart';
import '../theme.dart';
import '../widgets/uz_text.dart';
import 'aralash_mashq.dart';
import 'davom.dart';
import 'lesson/harflab_yozish.dart';
import 'lesson/qiyin_sozlar.dart';
import 'yozma_imtihon.dart';

/// Barcha darslardagi «Qiyin so'zlarim» bitta joyda — darsga kirmasdan,
/// istalgan bo'limdan ochiladi va hamma usulda mashq qilinadi.
class BarchaQiyin {
  BarchaQiyin._();

  /// Faqat son — kontent (repo) yuklanmagan bo'lsa ham ishlaydi.
  static int get soni => [
    for (final id in progress.tanlanganDarslar)
      ...progress.tanlanganlar(id),
  ].length;

  static List<(QiroatLesson, QiroatVocab)> royxat() {
    final idlar = progress.tanlanganDarslar.toSet();
    return [
      for (final l in repo.qiroatLessons)
        if (idlar.contains(l.completionId))
          for (final v in QiyinTanlov.sozlar(l.completionId)) (l, v),
    ];
  }
}

class BarchaQiyinEkrani extends StatefulWidget {
  const BarchaQiyinEkrani({super.key});
  @override
  State<BarchaQiyinEkrani> createState() => _BarchaQiyinEkraniState();
}

class _BarchaQiyinEkraniState extends State<BarchaQiyinEkrani> {
  List<(QiroatLesson, QiroatVocab)> get _r => BarchaQiyin.royxat();
  List<MashqElement> get _el => [
    for (final (l, v) in _r) QiyinTanlov.element(l, v),
  ];

  Future<void> _och(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    if (mounted) setState(() {});
  }

  void _aralash() {
    final r = _r;
    _och(
      AralashMashqEkrani(
        lesson: r.last.$1,
        faqat: [for (final x in r) x.$2],
        darsIdlar: {for (final x in r) x.$2.ar: x.$1.completionId},
        sarlavha: "Qiyin so'zlarim",
      ),
    );
  }

  void _test() {
    final r = _r;
    _och(
      MashqEkran(
        sarlavha: "Qiyin so'zlarim — test",
        darsniki: _el,
        oldingilar: MashqBank.qiroatGacha(r.last.$1),
      ),
    );
  }

  void _harflab() {
    final ro = <({String ar, String uz})>[];
    final k = <String, String>{};
    void qosh(String ar, String uz, String kalit) {
      final n = harflab(ar).length;
      if (n < 2 || n > 9 || ar.contains(' ')) return;
      ro.add((ar: ar, uz: uz));
      k[ar] = kalit;
    }

    for (final e in _el) {
      qosh(e.ar, e.uz, e.kalit);
      for (final pl in e.plShakllari) {
        qosh(pl, "${e.uz} — KO'PLIGI", e.kalit);
      }
    }
    if (ro.isEmpty) return;
    _och(
      HarflabYozishEkrani.royxat(
        sozRoyxati: ro,
        kalitlar: k,
        sarlavha: 'Harflab yozing',
      ),
    );
  }

  void _yozma() {
    final ro = <YozmaTopshiriq>[];
    for (final e in _el) {
      if (e.ar.contains(' ')) continue;
      ro.add(YozmaTopshiriq(uz: e.uz, ar: e.ar, kalit: e.kalit));
      for (final pl in e.plShakllari) {
        if (!pl.contains(' ')) {
          ro.add(
            YozmaTopshiriq(uz: "${e.uz} — KO'PLIGI", ar: pl, kalit: e.kalit),
          );
        }
      }
    }
    if (ro.isEmpty) return;
    _och(YozmaImtihonEkrani(topshiriqlar: ro, sarlavha: 'Eslab yozing'));
  }

  Future<void> _darsTanla() async {
    final oxirgi = oxirgiQiroatDarsi();
    final chegara = oxirgi == null ? 1001 : oxirgi.book * 1000 + oxirgi.num;
    final darslar = repo.qiroatLessons
        .where((l) => l.book * 1000 + l.num <= chegara)
        .toList()
        .reversed
        .toList();
    final l = await showModalBottomSheet<QiroatLesson>(
      context: context,
      builder: (c) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Qaysi darsdan so'z tanlaysiz?",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
          for (final d in darslar)
            ListTile(
              title: Text('${d.book}-kitob, ${d.num}-dars'),
              trailing: QiyinTanlov.sozlar(d.completionId).isEmpty
                  ? null
                  : Text('${QiyinTanlov.sozlar(d.completionId).length} ta'),
              onTap: () => Navigator.pop(c, d),
            ),
        ],
      ),
    );
    if (l != null) await _och(QiyinSozlarEkrani(lesson: l));
  }

  Widget _tugma(String nom, IconData i, Color c, VoidCallback f, Key k) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: k,
            onPressed: f,
            icon: Icon(i),
            label: Text(nom),
            style: FilledButton.styleFrom(
              backgroundColor: c,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return Scaffold(
      appBar: AppBar(title: Text("Qiyin so'zlarim (${r.length} ta)")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            key: const ValueKey('qiyin-dars-tanla'),
            onPressed: _darsTanla,
            icon: const Icon(Icons.add_rounded),
            label: Text("Darsdan so'z qo'shish"),
          ),
          const SizedBox(height: 14),
          if (r.isEmpty)
            Text(
              "Hali qiyin so'z tanlanmagan. Yuqoridagi tugma orqali istalgan "
              "darsdan yoki istalgan so'z ustiga bosib qo'shing.",
              style: TextStyle(color: AppColors.matn2),
            )
          else ...[
            _tugma(
              "Aralash mashq (hamma o'yinlar)",
              Icons.shuffle_rounded,
              AppColors.coral,
              _aralash,
              const ValueKey('qb-aralash'),
            ),
            _tugma(
              'Test',
              Icons.quiz_rounded,
              AppColors.emerald,
              _test,
              const ValueKey('qb-test'),
            ),
            _tugma(
              'Harflab yozish',
              Icons.abc_rounded,
              AppColors.teal,
              _harflab,
              const ValueKey('qb-harflab'),
            ),
            _tugma(
              'Eslab yozish',
              Icons.keyboard_rounded,
              AppColors.gold,
              _yozma,
              const ValueKey('qb-yozma'),
            ),
            const SizedBox(height: 8),
            for (final (l, v) in r)
              Card(
                child: ListTile(
                  title: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      [v.ar, if (v.pl.isNotEmpty) v.pl].join('  ،  '),
                      style: AppTheme.arabic(size: 22),
                    ),
                  ),
                  subtitle: Text('${v.uz}  ·  ${l.book}-kitob ${l.num}-dars'),
                  trailing: IconButton(
                    tooltip: "Ro'yxatdan olish",
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () async {
                      await QiyinTanlov.almashtir(l.completionId, v);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Ekran tepasidagi bayroqcha — «Qiyin so'zlarim»ni istalgan joydan ochadi.
class QiyinGlobalTugma extends StatelessWidget {
  const QiyinGlobalTugma({super.key});
  @override
  Widget build(BuildContext context) {
    final n = BarchaQiyin.soni;
    return IconButton(
      key: const ValueKey('qiyin-global'),
      tooltip: "Qiyin so'zlarim",
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BarchaQiyinEkrani()),
      ),
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text('$n'),
        child: const Icon(Icons.flag_rounded),
      ),
    );
  }
}

/// Bosh ekran kartasi: barcha qiyin so'zlar — bir bosishda mashq.
class QiyinSozlarKarta extends StatelessWidget {
  const QiyinSozlarKarta({super.key});
  @override
  Widget build(BuildContext context) {
    final n = BarchaQiyin.soni;
    return Card(
      key: const ValueKey('qiyin-karta'),
      child: ListTile(
        leading: const Icon(Icons.flag_rounded, color: Color(0xFFEC4899)),
        title: Text(
          "Qiyin so'zlarim",
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          n == 0
              ? "Yodlash qiyin so'zlarni tanlang — hamma darslardan"
              : "$n ta so'z — darsga kirmasdan mashq qiling",
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BarchaQiyinEkrani()),
        ),
      ),
    );
  }
}
