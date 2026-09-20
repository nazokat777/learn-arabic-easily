import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../arabic.dart';
import '../content.dart';
import '../main.dart';
import '../mashq/bank.dart';
import '../mashq/element.dart';
import '../mashq/mashq_ekran.dart';
import '../theme.dart';
import '../widgets/entrance.dart';
import '../widgets/motion.dart';
import '../widgets/uz_text.dart';
import 'bosh_joy.dart';
import 'gap_tuzish_ekrani.dart';
import 'lesson/gap_tuzish.dart';
import 'lesson/harflab_yozish.dart';
import 'yozma_imtihon.dart';
import '../harflab.dart';

/// IMTIHON — shu darsgacha o'tilgan HAMMA lug'at (1-darsdan shu darsgacha,
/// oldingi kitoblar ham) bo'yicha yig'ma sinov.
///
/// Nega: darsma-dars test faqat shu darsning so'zlarini so'raydi; 13-darsga
/// kelganda 1-darsning so'zi unutilgan bo'lsa, buni hech kim sezmaydi.
/// Imtihon esa BUTUN havzani ko'radi: qaysi so'z «yodlangan» darajaga
/// yetmagan — o'shani birinchi so'raydi, to har biri mustahkam bo'lguncha.
/// Uch qism: lug'at (zaif so'zlardan boshlab, moslashuvchan mashq),
/// jumlalar ichida (bo'sh joy — so'z o'z o'rnida), tinglab gap tuzish.
class ImtihonEkrani extends StatefulWidget {
  final QiroatLesson lesson;
  const ImtihonEkrani({super.key, required this.lesson});

  /// Bir kirishda nechta so'z so'raladi — ko'p bo'lsa charchatadi, oz bo'lsa
  /// havza yopilmaydi; 20 — bir o'tirishda tugaydigan hajm.
  static const int hajm = 20;

  @override
  State<ImtihonEkrani> createState() => _ImtihonEkraniState();
}

class _ImtihonEkraniState extends State<ImtihonEkrani> {
  final _rnd = Random();
  late final List<MashqElement> _havza = MashqBank.qiroatGacha(widget.lesson);
  late final List<QiroatLesson> _darslar = repo.qiroatLessons
      .where(
        (x) =>
            x.book * 1000 + x.num <=
            widget.lesson.book * 1000 + widget.lesson.num,
      )
      .toList();

  int get _yodlangan => _havza.where((e) => e.yodlangan).length;
  List<MashqElement> get _zaiflar =>
      _havza.where((e) => !e.yodlangan).toList()
        ..sort((a, b) => b.zaiflik.compareTo(a.zaiflik));

  String get _nom {
    final l = widget.lesson;
    return l.book == 1
        ? '1–${l.num}-darslar'
        : '${l.book}-kitob ${l.num}-darsgacha';
  }

  /// Zaif so'zlardan (yodlanmaganlar) 20 tasi; hammasi yodlangan bo'lsa —
  /// eng zaif 20 tasi (mustahkamlash).
  List<MashqElement> _navbatdagi() {
    final z = _zaiflar;
    if (z.length >= ImtihonEkrani.hajm) {
      // Eng zaiflar orasidan tasodifiy — har safar bir xil 20 ta chiqmasin.
      final ustki = z.take(ImtihonEkrani.hajm * 2).toList()..shuffle(_rnd);
      return ustki.take(ImtihonEkrani.hajm).toList();
    }
    final qolgan = List.of(_havza)
      ..removeWhere((e) => z.contains(e))
      ..sort((a, b) => b.zaiflik.compareTo(a.zaiflik));
    return [...z, ...qolgan.take(ImtihonEkrani.hajm - z.length)];
  }

  /// Asosiy imtihon: o'zbekcha ma'no beriladi, o'quvchi arabchasini HARFLAB
  /// yig'adi — birligini ham, kitobda bo'lsa ko'pligini ham. Tanlashdan
  /// farqli, bu yerda javob ko'z oldida turmaydi: so'z chindan xotiradan
  /// chiqadi.
  Future<void> _harflab() async {
    final tanlangan = _navbatdagi();
    if (tanlangan.isEmpty) return;
    final royxat = <({String ar, String uz})>[];
    final kalitlar = <String, String>{};
    for (final e in tanlangan) {
      final n = harflab(e.ar).length;
      if (n >= 2 && n <= 9 && !e.ar.contains(' ')) {
        royxat.add((ar: e.ar, uz: e.uz));
        kalitlar[e.ar] = e.kalit;
      }
      // Ko'pligi ham so'raladi — kitob lug'ati ikkalasini birga beradi.
      for (final pl in e.plShakllari) {
        final m = harflab(pl).length;
        if (m >= 2 && m <= 9 && !pl.contains(' ')) {
          royxat.add((ar: pl, uz: "${e.uz} — KO'PLIGI"));
          kalitlar[pl] = e.kalit;
        }
      }
    }
    if (royxat.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HarflabYozishEkrani.royxat(
          sozRoyxati: royxat,
          kalitlar: kalitlar,
          sarlavha: 'Imtihon — harflab yozing',
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  /// YOZMA — variantsiz: o'zbekchasi beriladi, arabchasini o'zi teradi
  /// (birligi va ko'pligi). Javob ko'rsatilmaydi — faqat ovoz.
  Future<void> _yozmaSozlar() async {
    final tanlangan = _navbatdagi();
    if (tanlangan.isEmpty) return;
    final ro = <YozmaTopshiriq>[];
    for (final e in tanlangan) {
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YozmaImtihonEkrani(
          topshiriqlar: ro,
          sarlavha: 'Yozma imtihon — so\'zlar',
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  /// YOZMA JUMLALAR — o'zbekcha jumla beriladi, arabchasini o'zi yozadi.
  /// Faqat jumlalar soni tarjima bilan aynan mos darslardan (aniqlik).
  void _yozmaJumlalar() {
    final ro = <YozmaTopshiriq>[];
    for (final l in _darslar) {
      final ar = splitSentences(l.reading);
      final uz = splitSentences(l.translation);
      if (ar.length != uz.length) continue;
      for (var i = 0; i < ar.length; i++) {
        final n = GapTuzish.sozlar(ar[i]).length;
        if (n >= 2 && n <= 8) ro.add(YozmaTopshiriq(uz: uz[i], ar: ar[i]));
      }
    }
    if (ro.isEmpty) return;
    ro.shuffle(_rnd);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YozmaImtihonEkrani(
          topshiriqlar: ro.take(10).toList(),
          sarlavha: 'Yozma imtihon — jumlalar',
          jumla: true,
        ),
      ),
    );
  }

  Future<void> _lugat() async {
    final tanlangan = _navbatdagi();
    if (tanlangan.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MashqEkran(
          sarlavha: 'Imtihon — $_nom',
          darsniki: tanlangan,
          oldingilar: _havza,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _jumlalar() async {
    final hammasi = <BoshJoy>[];
    for (final l in _darslar) {
      hammasi.addAll(BoshJoy.yasa(l));
    }
    if (hammasi.isEmpty) return;
    // Yodlanmagan so'zlarning jumlalari oldin, keyin qolganlari.
    final zaifAr = _zaiflar.map((e) => stripDiacritics(e.ar)).toSet();
    final zaif =
        hammasi
            .where(
              (b) => zaifAr.contains(
                stripDiacritics(splitForms(b.lugat.ar).first),
              ),
            )
            .toList()
          ..shuffle(_rnd);
    final boshqa = hammasi.where((b) => !zaif.contains(b)).toList()
      ..shuffle(_rnd);
    final royxat = [...zaif, ...boshqa].take(ImtihonEkrani.hajm).toList();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BoshJoyEkrani.royxat(
          royxat: royxat,
          sarlavha: 'Imtihon — jumlada top',
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _gapTuzish() {
    final juftlar = <(String, String)>[];
    for (final l in _darslar) {
      final ar = splitSentences(l.reading);
      final uz = splitSentences(l.translation);
      final mos = ar.length == uz.length;
      for (var i = 0; i < ar.length; i++) {
        if (GapTuzish.sozlar(ar[i]).length >= 3) {
          juftlar.add((mos ? uz[i] : '', ar[i]));
        }
      }
    }
    if (juftlar.isEmpty) return;
    juftlar.shuffle(_rnd);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GapTuzishEkrani(
          juftlar: juftlar.take(12).toList(),
          title: 'Imtihon — tinglab tuzish',
          tinglab: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jami = _havza.length;
    final yod = _yodlangan;
    final zaif = _zaiflar;
    final ulush = jami == 0 ? 0.0 : yod / jami;
    return Scaffold(
      appBar: AppBar(title: Text('Imtihon — $_nom')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              // Umumiy holat: havza qanchalik yopilgan.
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.karta,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shu darsgacha bo\'lgan hamma so\'z',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedBar(
                      value: ulush,
                      height: 10,
                      color: AppColors.success,
                      background: AppColors.success.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yodlangan: $yod / $jami so\'z'
                      '${zaif.isEmpty ? " — hammasi mustahkam!" : "   ·   hali mustahkam emas: ${zaif.length}"}',
                      style: TextStyle(color: AppColors.matn2, fontSize: 13.5),
                    ),
                    if (_darslar.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${_darslar.length} ta darsning lug\'ati va jumlalari',
                          style: TextStyle(
                            color: AppColors.matn3,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _tugma(
                rang: AppColors.coral,
                ikon: Icons.edit_rounded,
                nom: "Yozma — so'zlar (variantsiz)",
                izoh:
                    "O'zbekchasi beriladi, arabchasini o'zingiz yozasiz — birligi va ko'pligi; javob ko'rsatilmaydi, faqat ovoz",
                onTap: _yozmaSozlar,
              ),
              const SizedBox(height: 10),
              _tugma(
                rang: AppColors.coral,
                ikon: Icons.edit_note_rounded,
                nom: "Yozma — jumlalar (variantsiz)",
                izoh:
                    "O'zbekcha jumla beriladi, arabchasini o'zingiz yozasiz; bilmasangiz ovozda eshitasiz",
                onTap: _yozmaJumlalar,
              ),
              const SizedBox(height: 10),
              _tugma(
                rang: AppColors.indigo,
                ikon: Icons.spellcheck_rounded,
                nom: zaif.isEmpty
                    ? "Harflab yozing — mustahkamlash (20 so'z)"
                    : "Harflab yozing — zaif so'zlar (${min(zaif.length, ImtihonEkrani.hajm)} ta)",
                izoh:
                    "O'zbekchasi beriladi, arabchasini harfma-harf yozasiz — birligi va ko'pligi",
                onTap: _harflab,
              ),
              const SizedBox(height: 10),
              _tugma(
                rang: AppColors.gold,
                ikon: Icons.style_rounded,
                nom: 'Aralash mashq — tanish, eslash, tinglash',
                izoh: "Zaif so'zlar birinchi; to'g'ri javob bergancha qaytadi",
                onTap: _lugat,
              ),
              const SizedBox(height: 10),
              _tugma(
                rang: AppColors.indigo,
                ikon: Icons.space_bar_rounded,
                nom: 'Jumlalar ichida — bo\'sh joy',
                izoh:
                    'So\'z kitob jumlasida o\'z o\'rnida; zaif so\'zlar oldin',
                onTap: _jumlalar,
              ),
              const SizedBox(height: 10),
              _tugma(
                rang: AppColors.emerald,
                ikon: Icons.hearing_rounded,
                nom: 'Tinglab gap tuzish',
                izoh: 'Barcha o\'tilgan matnlardan 12 jumla',
                onTap: _gapTuzish,
              ),
              if (zaif.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  'Hali mustahkam bo\'lmagan so\'zlar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in zaif.take(40))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                e.ar,
                                style: AppTheme.arabic(
                                  size: 18,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              e.uz,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.matn2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (zaif.length > 40)
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          '… yana ${zaif.length - 40} ta',
                          style: TextStyle(color: AppColors.matn3),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tugma({
    required Color rang,
    required IconData ikon,
    required String nom,
    required String izoh,
    required VoidCallback onTap,
  }) => PressableScale(
    child: Material(
      color: rang,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(ikon, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    Text(
                      izoh,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    ),
  );
}
