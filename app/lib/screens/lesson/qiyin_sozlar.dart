import 'package:flutter/material.dart' hide Text;

import '../../arabic.dart';
import '../../content.dart';
import '../../harflab.dart';
import '../../lugat.dart';
import '../../main.dart';
import '../../mashq/bank.dart';
import '../../mashq/element.dart';
import '../../mashq/mashq_ekran.dart';
import '../../theme.dart';
import '../../widgets/speak_button.dart';
import '../../widgets/uz_text.dart';
import '../aralash_mashq.dart';
import '../bosh_joy.dart';
import '../yozma_imtihon.dart';
import 'birlik_koplik.dart';
import 'harflab_yozish.dart';

/// «Qiyin so'zlarim» — o'quvchi yodlay olmayotgan so'zlarini o'zi tanlaydi
/// (lug'atdan, gaplardan yoki so'z kartasidan), ilova ularni ketma-ket
/// beshta usulda ishlatadi. Tanlov dars bo'yicha saqlanadi.
class QiyinTanlov {
  QiyinTanlov._();

  /// Ketma-ket shuncha to'g'ri javobdan keyin so'z «yodlandi» deb ko'rsatiladi.
  static const int yodlandi = 5;

  static String kalit(String darsId, QiroatVocab v) =>
      'qiroat::$darsId::${v.ar}';

  static List<QiroatVocab> sozlar(String darsId) => [
    for (final m in progress.tanlanganlar(darsId))
      QiroatVocab(ar: m['ar'] ?? '', pl: m['pl'] ?? '', uz: m['uz'] ?? ''),
  ];

  static bool bormi(String darsId, QiroatVocab v) =>
      progress.tanlanganMi(darsId, v.ar);

  static Future<void> almashtir(String darsId, QiroatVocab v) =>
      progress.tanlanganAlmashtir(darsId, {'ar': v.ar, 'pl': v.pl, 'uz': v.uz});

  /// Gaplardagi, lug'at ro'yxatida yo'q, lekin ma'nosi ANIQ topilgan so'zlar.
  /// Ma'nosi topilmagani chiqmaydi — taxminiy tarjima bilan yodlatilmaydi.
  static List<QiroatVocab> gapSozlari(QiroatLesson l) {
    final lugatda = <String>{
      for (final v in l.vocab)
        for (final f in splitForms(v.ar)) Lugat.kalit(f),
      for (final v in l.vocab)
        for (final f in v.plShakllari) Lugat.kalit(f),
    };
    final korilgan = <String>{};
    final natija = <QiroatVocab>[];
    final matn = [l.reading, for (final j in l.mashqJuftlar) j.ar].join(' ');
    for (final t in tokenize(matn)) {
      if (!t.isWord) continue;
      final top = Lugat.instance.qidir(t.text);
      if (top == null || top.soz.uz.trim().isEmpty) continue;
      final v = top.soz;
      final k = Lugat.kalit(splitForms(v.ar).first);
      if (lugatda.contains(k) || !korilgan.add(k)) continue;
      natija.add(v);
    }
    return natija;
  }

  static MashqElement element(QiroatLesson l, QiroatVocab v) => MashqElement(
    kalit: kalit(l.completionId, v),
    ar: splitForms(v.ar).first,
    uz: v.uz,
    darsId: l.completionId,
    tartib: l.book * 1000 + l.num,
    modul: 'Mabdaul qiroat',
    pl: v.pl,
  );
}

class QiyinSozlarEkrani extends StatefulWidget {
  final QiroatLesson lesson;
  const QiyinSozlarEkrani({super.key, required this.lesson});

  @override
  State<QiyinSozlarEkrani> createState() => _QiyinSozlarEkraniState();
}

class _QiyinSozlarEkraniState extends State<QiyinSozlarEkrani> {
  QiroatLesson get _l => widget.lesson;
  String get _id => _l.completionId;
  late final List<QiroatVocab> _gap = QiyinTanlov.gapSozlari(_l);

  /// Ko'p xato qilingan so'zlar tepada — tanlashni osonlashtiradi.
  late final List<QiroatVocab> _lugat = () {
    final seen = <String>{};
    final r = [
      for (final v in _l.vocab)
        if (v.ar.trim().isNotEmpty && v.uz.trim().isNotEmpty && seen.add(v.uz))
          v,
    ];
    final tartib = {for (final (i, v) in r.indexed) v.ar: i};
    r.sort((a, b) {
      final x = _xato(b).compareTo(_xato(a));
      return x != 0 ? x : tartib[a.ar]!.compareTo(tartib[b.ar]!);
    });
    return r;
  }();

  int _xato(QiroatVocab v) => progress.xatoSoni(QiyinTanlov.kalit(_id, v));
  List<QiroatVocab> get _tanlangan => QiyinTanlov.sozlar(_id);
  List<MashqElement> get _elementlar => [
    for (final v in _tanlangan) QiyinTanlov.element(_l, v),
  ];

  Future<void> _och(Widget Function() e) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => e()));
    if (mounted) setState(() {});
  }

  Widget _test() => MashqEkran(
    sarlavha: "Qiyin so'zlarim",
    darsniki: _elementlar,
    oldingilar: MashqBank.qiroatGacha(_l),
  );

  Widget _ayt() => Builder(
    builder: (c) => Scaffold(
      appBar: AppBar(title: Text("Birligi va ko'pligi")),
      body: BirlikKoplikAyt(
        sozlar: _tanlangan,
        darsId: 'qiroat::$_id',
        onDone: () => Navigator.pop(c),
      ),
    ),
  );

  Widget? _harflab() {
    final ro = <({String ar, String uz})>[];
    final kalit = <String, String>{};
    void qosh(String ar, String uz, String k) {
      final n = harflab(ar).length;
      if (n < 2 || n > 9 || ar.contains(' ')) return;
      ro.add((ar: ar, uz: uz));
      kalit[ar] = k;
    }

    for (final e in _elementlar) {
      qosh(e.ar, e.uz, e.kalit);
      for (final pl in e.plShakllari) {
        qosh(pl, "${e.uz} — KO'PLIGI", e.kalit);
      }
    }
    if (ro.isEmpty) return null;
    return HarflabYozishEkrani.royxat(
      sozRoyxati: ro,
      kalitlar: kalit,
      sarlavha: 'Harflab yozing',
    );
  }

  Widget? _yozma() {
    final ro = <YozmaTopshiriq>[];
    for (final e in _elementlar) {
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
    if (ro.isEmpty) return null;
    return YozmaImtihonEkrani(topshiriqlar: ro, sarlavha: 'Eslab yozing');
  }

  /// Tanlangan so'zlar qatnashgan kitob jumlalari — yo'q bo'lsa `null`.
  Widget? _gapda() {
    final ro = BoshJoy.yasa(
      QiroatLesson(
        book: _l.book,
        num: _l.num,
        titleAr: _l.titleAr,
        reading: _l.reading,
        vocab: _tanlangan,
      ),
    );
    if (ro.isEmpty) return null;
    return BoshJoyEkrani.royxat(royxat: ro, sarlavha: 'Gap ichida');
  }

  List<(String, IconData, Widget? Function())> get _usullar => [
    (
      'Aralash',
      Icons.shuffle_rounded,
      () => AralashMashqEkrani(
        lesson: _l,
        faqat: _tanlangan,
        sarlavha: "Qiyin so'zlarim — aralash",
      ),
    ),
    ('Test', Icons.quiz_rounded, () => _test()),
    ('Ayting', Icons.record_voice_over_rounded, () => _ayt()),
    ('Harflab', Icons.spellcheck_rounded, _harflab),
    ('Gapda', Icons.notes_rounded, _gapda),
    ('Yozing', Icons.keyboard_rounded, _yozma),
  ];

  /// Beshala usul ketma-ket; orqaga chiqilsa keyingisiga o'tadi.
  Future<void> _hammasi() async {
    for (final (_, _, yasa) in _usullar) {
      final e = yasa();
      if (e == null) continue;
      await _och(() => e);
      if (!mounted) return;
    }
  }

  Widget _qator(QiroatVocab v) {
    final tanlandi = QiyinTanlov.bormi(_id, v);
    final xato = _xato(v);
    final ketma = progress.ketmaKetTogri(QiyinTanlov.kalit(_id, v));
    final bosh = splitForms(v.ar).first;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: tanlandi
          ? AppColors.gold.withValues(alpha: 0.14)
          : AppColors.karta,
      child: InkWell(
        key: ValueKey('qiyin-${v.ar}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await QiyinTanlov.almashtir(_id, v);
          if (mounted) setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
          child: Row(
            children: [
              Checkbox(
                value: tanlandi,
                onChanged: null,
                fillColor: WidgetStateProperty.resolveWith(
                  (s) => tanlandi ? AppColors.gold : null,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.uz,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (tanlandi && ketma >= QiyinTanlov.yodlandi)
                      Text(
                        "Yodlandi — belgini olib tashlashingiz mumkin",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else if (tanlandi)
                      Text(
                        "Ketma-ket to'g'ri: $ketma/${QiyinTanlov.yodlandi}",
                        style: TextStyle(fontSize: 12, color: AppColors.matn3),
                      )
                    else if (xato > 0)
                      Text(
                        '$xato marta xato qilingan',
                        style: TextStyle(fontSize: 12, color: AppColors.matn3),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bosh,
                        style: AppTheme.arabic(size: 22, color: AppColors.ink),
                      ),
                      if (v.plShakllari.isNotEmpty)
                        Text(
                          v.plShakllari.join(' ، '),
                          style: AppTheme.arabic(
                            size: 17,
                            color: AppColors.gold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SpeakButton(text: bosh, id: 'qs-${v.ar}', size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sarlavha(String s) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Text(
      s,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final soni = _tanlangan.length;
    return Scaffold(
      appBar: AppBar(title: Text("Qiyin so'zlarim")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            "Yodlay olmayotgan so'zlaringizni belgilang — ilova ularni "
            "test, aytish, harflash, gap va yozish orqali mustahkamlaydi.",
            style: TextStyle(fontSize: 13.5, color: AppColors.matn2),
          ),
          const SizedBox(height: 12),
          if (soni > 0) ...[
            FilledButton.icon(
              key: const ValueKey('qiyin-boshla'),
              onPressed: _hammasi,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text("Chuqur mashq — $soni ta so'z"),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (nom, belgi, yasa) in _usullar)
                  // Test ochilgandagina yasaladi: havzasi butun kitob lug'ati.
                  if (nom == 'Test' || yasa() != null)
                    ActionChip(
                      avatar: Icon(belgi, size: 17),
                      label: Text(nom),
                      onPressed: () => _och(() => yasa()!),
                    ),
              ],
            ),
          ],
          _sarlavha("Lug'atdan"),
          for (final v in _lugat) _qator(v),
          if (_gap.isNotEmpty) ...[
            _sarlavha('Gaplardan'),
            for (final v in _gap) _qator(v),
          ],
        ],
      ),
    );
  }
}

/// Dars sahifasi va dars yakunidagi tugma.
class QiyinSozlarTugmasi extends StatelessWidget {
  final QiroatLesson lesson;
  const QiyinSozlarTugmasi({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final n = QiyinTanlov.sozlar(lesson.completionId).length;
    return FilledButton.icon(
      key: const ValueKey('qiyin-sozlar'),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QiyinSozlarEkrani(lesson: lesson)),
      ),
      icon: const Icon(Icons.flag_rounded),
      label: Text(
        n == 0 ? "Qiyin so'zlarimni tanlash" : "Qiyin so'zlarim ($n ta)",
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.emerald,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
