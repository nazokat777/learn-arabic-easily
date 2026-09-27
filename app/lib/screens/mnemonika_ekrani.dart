import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import 'package:url_launcher/url_launcher.dart';

import '../arabic.dart';
import '../main.dart';
import '../mashq/element.dart';
import '../mashq/mashq_ekran.dart';
import '../mnemonika/reja.dart';
import '../mnemonika/xarita.dart';
import '../services/eslatma.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/uz_text.dart';
import 'bosh_joy.dart';
import 'gap_tuzish_ekrani.dart';
import 'ilgak_mashqi.dart';
import 'lesson/gap_tuzish.dart';
import 'yozma_imtihon.dart';

/// MNEMONIKA — kitobni kunlarga bo'lib, xotira usullari bilan yodlash.
///
/// Uch qism:
///  • Bugun — kunlik cheklist («7 qadamli algoritm»), zanjir, eslatma,
///    diqqat taymeri;
///  • Xarita va reja — har kitobda nechta dars, lug'at, qoida; tanlangan
///    muddatga (2 hafta … 6 oy) bo'lib, kuniga qancha ekanini hisoblash;
///  • Usullar — neyrobiologik va mnemonik tamoyillar qisqacha.
class MnemonikaEkrani extends StatefulWidget {
  const MnemonikaEkrani({super.key});

  @override
  State<MnemonikaEkrani> createState() => _MnemonikaEkraniState();
}

class _MnemonikaEkraniState extends State<MnemonikaEkrani>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(
    length: 3,
    vsync: this,
    initialIndex: RejaXotira.instance.rejalar.isEmpty ? 1 : 0,
  );

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mnemonika — yodlash xaritasi'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.zumradMatn,
          unselectedLabelColor: AppColors.matn2,
          indicatorColor: AppColors.gold,
          tabs: const [
            Tab(text: 'Bugun'),
            Tab(text: 'Xarita va reja'),
            Tab(text: 'Usullar'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: RejaXotira.instance,
        builder: (context, _) => TabBarView(
          controller: _tab,
          children: [
            _BugunQismi(rejaTuzish: () => _tab.animateTo(1)),
            _XaritaQismi(rejaBoshlandi: () => _tab.animateTo(0)),
            const _UsullarQismi(),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Umumiy bezaklar
// =====================================================================

Widget _karta({required Widget child, Color? chegara}) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.karta,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: chegara ?? AppColors.chiziq2),
  ),
  child: child,
);

Widget _markaz(List<Widget> children) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 680),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: children,
    ),
  ),
);

String _oy(int kun) {
  if (kun % 30 == 0) return '${kun ~/ 30} oy';
  if (kun % 7 == 0 && kun < 60) return '${kun ~/ 7} hafta';
  if (kun > 45) return '$kun kun (≈${(kun / 30).toStringAsFixed(1)} oy)';
  return '$kun kun';
}

String _sana(int kunRaqami) {
  final d = DateTime.utc(1970).add(Duration(days: kunRaqami));
  const oylar = [
    'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
    'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr',
  ];
  return '${d.day}-${oylar[d.month - 1]}';
}

// =====================================================================
// 1. BUGUN
// =====================================================================

class _BugunQismi extends StatefulWidget {
  final VoidCallback rejaTuzish;
  const _BugunQismi({required this.rejaTuzish});

  @override
  State<_BugunQismi> createState() => _BugunQismiState();
}

class _BugunQismiState extends State<_BugunQismi> {
  /// Bugungi kun bajarilgach «ertangi kunni hozir boshlash» bosilgan rejalar.
  final Set<String> _oldinga = {};

  @override
  Widget build(BuildContext context) {
    final x = RejaXotira.instance;
    if (x.rejalar.isEmpty) {
      return _markaz([
        const SizedBox(height: 30),
        const Icon(Icons.map_rounded, size: 64, color: AppColors.gold),
        const SizedBox(height: 14),
        Text(
          'Hali reja yo\'q',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Kitobni tanlang, muddatni belgilang — ilova uni kunlarga bo'lib "
          "beradi: har kuni nechta so'z, qaysi dars, qaysi qoida. Keyin har "
          "kuni cheklist bo'yicha yodlaysiz.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.matn2, height: 1.45),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: widget.rejaTuzish,
            icon: const Icon(Icons.add_road_rounded),
            label: const Text('Reja tuzish'),
          ),
        ),
      ]);
    }
    return _markaz([
      _ZanjirKartasi(),
      const SizedBox(height: 12),
      const _DiqqatTaymeri(),
      const SizedBox(height: 12),
      for (final r in x.rejalar) ...[
        _RejaKartasi(
          reja: r,
          oldinga: _oldinga.contains(r.kitobId),
          oldingaBos: () => setState(() => _oldinga.add(r.kitobId)),
        ),
        const SizedBox(height: 14),
      ],
      Center(
        child: TextButton.icon(
          onPressed: widget.rejaTuzish,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yana bir kitobga reja tuzish'),
        ),
      ),
    ]);
  }
}

class _ZanjirKartasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final x = RejaXotira.instance;
    final z = x.zanjir;
    final e = x.eslatmaDaqiqa;
    return _karta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                x.bugunFaol ? '🔥' : '🕯️',
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      z == 0 ? 'Zanjirni bugun boshlang' : 'Zanjir: $z kun',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      x.bugunFaol
                          ? "Bugungi kun bajarildi — zanjir uzilmadi."
                          : "Bittagina kunni to'liq bajarsangiz ham zanjir davom etadi. Uzmang.",
                      style: TextStyle(color: AppColors.matn2, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Icon(
                e == null
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_rounded,
                color: e == null ? AppColors.matn3 : AppColors.emerald,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e == null
                      ? 'Eslatma o\'chiq'
                      : 'Har kuni ${(e ~/ 60).toString().padLeft(2, '0')}:${(e % 60).toString().padLeft(2, '0')} da eslatadi',
                  style: TextStyle(color: AppColors.ink, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: () => _eslatmaTanla(context),
                child: Text(e == null ? 'Yoqish' : 'O\'zgartirish'),
              ),
              if (e != null)
                IconButton(
                  tooltip: 'O\'chirish',
                  onPressed: () => x.eslatmaQoy(null),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _eslatmaTanla(BuildContext context) async {
    final x = RejaXotira.instance;
    final e = x.eslatmaDaqiqa ?? 20 * 60;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: e ~/ 60, minute: e % 60),
      helpText: 'Har kuni qachon eslatsin?',
    );
    if (t == null) return;
    await x.eslatmaQoy(t.hour * 60 + t.minute);
    var xabar =
        "Eslatma qo'yildi. Ilova ochiq bo'lsa, vaqti kelganda xabar chiqadi; "
        "ochganingizda esa bugungi reja birinchi bo'lib ko'rinadi.";
    if (eslatmaQollanadi()) {
      final ok = await eslatmaRuxsatSora();
      if (!ok) {
        xabar =
            "Eslatma qo'yildi, lekin brauzer bildirishnomaga ruxsat bermadi — "
            "eslatma faqat ilova ichida ko'rinadi.";
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(xabar)));
    }
  }
}

/// Diqqat taymeri — 25 daqiqa ish, 5 daqiqa dam (pomidor usuli).
class _DiqqatTaymeri extends StatefulWidget {
  const _DiqqatTaymeri();

  @override
  State<_DiqqatTaymeri> createState() => _DiqqatTaymeriState();
}

class _DiqqatTaymeriState extends State<_DiqqatTaymeri> {
  static const _variantlar = [(15, 3), (25, 5), (50, 10)];
  int _tanlov = 1;
  Timer? _t;
  int _qoldi = 0; // soniya
  bool _dam = false;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _boshla() {
    final (ish, _) = _variantlar[_tanlov];
    setState(() {
      _dam = false;
      _qoldi = ish * 60;
    });
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _qoldi--;
        if (_qoldi <= 0) {
          final (ish, dam) = _variantlar[_tanlov];
          _dam = !_dam;
          _qoldi = (_dam ? dam : ish) * 60;
          eslatmaKorsat(
            _dam ? 'Dam oling' : 'Ishga qayting',
            _dam
                ? '$dam daqiqa tanaffus — ko\'zni yuming, cho\'zilib oling.'
                : 'Yangi $ish daqiqalik diqqat bloki boshlandi.',
          );
        }
      });
    });
  }

  void _toxtat() {
    _t?.cancel();
    setState(() {
      _t = null;
      _qoldi = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ishlayapti = _t != null;
    final m = (_qoldi ~/ 60).toString().padLeft(2, '0');
    final s = (_qoldi % 60).toString().padLeft(2, '0');
    return _karta(
      child: Row(
        children: [
          Icon(
            Icons.timer_rounded,
            color: _dam ? AppColors.teal : AppColors.coral,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ishlayapti
                ? Text(
                    '${_dam ? "Dam" : "Diqqat"}: $m:$s',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Diqqat taymeri',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      for (final (i, (ish, dam)) in _variantlar.indexed)
                        ChoiceChip(
                          label: Text('$ish/$dam'),
                          selected: _tanlov == i,
                          onSelected: (_) => setState(() => _tanlov = i),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
          ),
          IconButton.filledTonal(
            onPressed: ishlayapti ? _toxtat : _boshla,
            icon: Icon(
              ishlayapti ? Icons.stop_rounded : Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _RejaKartasi extends StatelessWidget {
  final Reja reja;
  final bool oldinga;
  final VoidCallback oldingaBos;
  const _RejaKartasi({
    required this.reja,
    required this.oldinga,
    required this.oldingaBos,
  });

  @override
  Widget build(BuildContext context) {
    final r = reja;
    final k = r.kitob!;
    final x = RejaXotira.instance;
    final kun = r.joriyKun;
    final tugadi = r.tugadi;
    final oldinda = !tugadi && kun > r.kalendarKun;
    final orqada = r.orqada;

    final sarlavha = Row(
      children: [
        Container(
          width: 10,
          height: 40,
          decoration: BoxDecoration(
            color: k.rang,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                k.nom,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${_oy(r.kunlar)}lik reja · tugash: ${_sana(r.boshKun + r.kunlar - 1)}',
                style: TextStyle(color: AppColors.matn2, fontSize: 12.5),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v != 'ochir') return;
            final ha = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Rejani o\'chirasizmi?'),
                content: const Text(
                  "Cheklist belgilari o'chadi. So'zlarni yodlaganingiz "
                  "(xotira darajasi) saqlanib qoladi.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Yo\'q'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('O\'chirish'),
                  ),
                ],
              ),
            );
            if (ha == true) await x.ochir(r.kitobId);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'ochir', child: Text('Rejani o\'chirish')),
          ],
        ),
      ],
    );

    final bar = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        AnimatedBar(
          value: r.tugaganKunlar / r.kunlar,
          height: 9,
          color: k.rang,
          background: k.rang.withValues(alpha: 0.12),
        ),
        const SizedBox(height: 6),
        Text(
          '${r.tugaganKunlar} / ${r.kunlar} kun bajarildi'
          '${orqada > 0 ? "  ·  rejadan $orqada kun orqadasiz — jazo yo'q, qolgan joydan davom eting" : ""}',
          style: TextStyle(
            color: orqada > 0 ? AppColors.coral : AppColors.matn2,
            fontSize: 12.5,
          ),
        ),
      ],
    );

    if (tugadi) {
      return _karta(
        chegara: AppColors.gold,
        child: Column(
          children: [
            sarlavha,
            bar,
            const SizedBox(height: 12),
            Text(
              "🎉 Kitob rejasi tugadi! Endi so'zlar faqat oraliqli "
              "takrorlashda (1-2-4-7-14-30 kun) qaytadi — Mashqlar bo'limidagi "
              "«Eslash vaqti keldi» orqali.",
              style: TextStyle(color: AppColors.ink, height: 1.4),
            ),
          ],
        ),
      );
    }

    if (oldinda && !oldinga) {
      return _karta(
        chegara: AppColors.success,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sarlavha,
            bar,
            const SizedBox(height: 12),
            Text(
              "✅ Bugungi reja bajarildi. Miya yangi ma'lumotni uyquda "
              "mustahkamlaydi — ertaga davom etish eng samarali yo'l.",
              style: TextStyle(color: AppColors.ink, height: 1.4),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: oldingaBos,
              icon: const Icon(Icons.fast_forward_rounded),
              label: const Text('Baribir ertangi kunni hozir boshlash'),
            ),
          ],
        ),
      );
    }

    final yangi = r.kunElementlari(kun);
    final darslar = r.kunDarslari(kun);
    final takror = r.takrorElementlari(kun);
    final qoidaSoni = k.lugatKitobi
        ? darslar.fold(0, (s, d) => s + d.qoida)
        : darslar.length;

    return _karta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sarlavha,
          bar,
          const SizedBox(height: 14),
          Text(
            '${kun + 1}-kun  ·  ${_sana(r.boshKun + kun)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: k.rang,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (k.lugatKitobi) "${yangi.length} ta yangi so'z",
              if (!k.lugatKitobi) '${darslar.length} ta dars (${yangi.length} misol)',
              if (k.lugatKitobi) '${darslar.length} ta dars matni',
              if (qoidaSoni > 0 && k.lugatKitobi) '$qoidaSoni ta grammatika jadvali',
              "${takror.length} ta takrorlash",
            ].join('  ·  '),
            style: TextStyle(color: AppColors.matn2, fontSize: 13),
          ),
          const SizedBox(height: 10),
          for (final (i, v) in r.vazifalar.indexed)
            _VazifaQatori(
              raqam: i + 1,
              reja: r,
              kun: kun,
              vazifa: v,
              yangi: yangi,
              darslar: darslar,
              takror: takror,
            ),
        ],
      ),
    );
  }
}

class _VazifaQatori extends StatelessWidget {
  final int raqam;
  final Reja reja;
  final int kun;
  final Vazifa vazifa;
  final List<MashqElement> yangi;
  final List<DarsBirlik> darslar;
  final List<MashqElement> takror;

  const _VazifaQatori({
    required this.raqam,
    required this.reja,
    required this.kun,
    required this.vazifa,
    required this.yangi,
    required this.darslar,
    required this.takror,
  });

  bool get _lugatli => reja.kitob!.lugatKitobi;

  (IconData, String, String) get _matn => switch (vazifa) {
    Vazifa.hajm => (
      Icons.visibility_rounded,
      "Ma'no va hajm",
      "Bugungi ${yangi.length} so'zni ko'ring, eshiting: ma'nosi, ko'pligi",
    ),
    Vazifa.ilgak => (
      Icons.link_rounded,
      'Ilgak va obraz',
      "Har so'zga tayyor ilgak va sahna — tasavvur qilib, keyin eslaysiz",
    ),
    Vazifa.qoida => (
      Icons.menu_book_rounded,
      _lugatli ? 'Dars matnini o\'qish' : 'Qoidani o\'qish',
      darslar.map((d) => d.nom).join(', '),
    ),
    Vazifa.eslash => (
      Icons.psychology_rounded,
      'Qaramasdan eslash',
      _lugatli
          ? "Arabchani ko'rib ma'nosini xotiradan toping"
          : "Qoida misollarini xotiradan toping",
    ),
    Vazifa.teskari => (
      Icons.edit_rounded,
      "O'zbekchadan arabchasini yozish",
      'Variantsiz — o\'zbekchasi beriladi, arabchasini o\'zingiz yozasiz',
    ),
    Vazifa.takror => (
      Icons.replay_rounded,
      'Oraliqli takrorlash',
      takror.isEmpty
          ? 'Bugun eslash vaqti kelgan so\'z yo\'q'
          : '${takror.length} ta — unutish boshlanayotgan paytda qaytarish',
    ),
    Vazifa.gap => (
      Icons.forum_rounded,
      'Hayotda qo\'llash',
      _lugatli
          ? "So'zni jumla ichida topish, gap tuzish"
          : 'Misol jumlalarni tinglab qayta tuzish',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final bajarildi = reja.bajarildimi(kun, vazifa);
    final (ikon, nom, izoh) = _matn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: bajarildi
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _bajar(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: bajarildi
                      ? AppColors.success
                      : reja.kitob!.rang.withValues(alpha: 0.15),
                  child: bajarildi
                      ? const Icon(Icons.check, size: 17, color: Colors.white)
                      : Icon(ikon, size: 16, color: reja.kitob!.rang),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$raqam. $nom',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          decoration: bajarildi
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (izoh.isNotEmpty)
                        Text(
                          izoh,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.matn2,
                            fontSize: 12.5,
                          ),
                        ),
                    ],
                  ),
                ),
                Checkbox(
                  value: bajarildi,
                  onChanged: (v) => RejaXotira.instance.belgila(
                    reja,
                    kun,
                    vazifa,
                    v ?? false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _ot(BuildContext context, Widget sahifa) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => sahifa));

  /// Elementlar bo'yicha jami urinishlar (progress'dagi).
  static int _urinish(Iterable<MashqElement> els) =>
      els.fold(0, (s, e) => s + progress.urinishSoni(e.kalit));

  Future<void> _bajar(BuildContext context) async {
    final x = RejaXotira.instance;
    final nom = reja.kitob!.nom;
    var bajarildi = true;

    // Mashq qadamlari faqat chindan ishlanganda belgilanadi: kamida
    // so'zlarning yarmicha javob berilgan bo'lishi kerak.
    final olchov = switch (vazifa) {
      Vazifa.eslash || Vazifa.teskari => yangi,
      Vazifa.takror => takror,
      _ => const <MashqElement>[],
    };
    final oldin = _urinish(olchov);

    switch (vazifa) {
      case Vazifa.hajm:
        final r = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => KunSozlariEkrani(
              sozlar: yangi,
              ilgakRejimi: false,
              sarlavha: "${kun + 1}-kun — bugungi so'zlar",
            ),
          ),
        );
        bajarildi = r ?? false;

      case Vazifa.ilgak:
        if (yangi.isEmpty) break;
        final r = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => IlgakMashqi(
              sozlar: yangi,
              sarlavha: '${kun + 1}-kun — ilgak va sahna',
            ),
          ),
        );
        bajarildi = r ?? false;

      case Vazifa.qoida:
        if (darslar.isEmpty) break;
        if (darslar.length == 1) {
          await _ot(context, darslar.first.sahifa());
        } else {
          await showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (c) => ListView(
              shrinkWrap: true,
              children: [
                for (final d in darslar)
                  ListTile(
                    leading: const Icon(Icons.menu_book_rounded),
                    title: Text(d.nom),
                    subtitle: d.lugat > 0
                        ? Text("${d.lugat} lug'at")
                        : null,
                    onTap: () => _ot(c, d.sahifa()),
                  ),
              ],
            ),
          );
        }

      case Vazifa.eslash:
        if (yangi.isEmpty) break;
        await _ot(
          context,
          MashqEkran(
            sarlavha: '$nom — ${kun + 1}-kun',
            darsniki: yangi,
            oldingilar: reja.hammaElement,
          ),
        );

      case Vazifa.teskari:
        final ro = _yozma(yangi, _lugatli ? 999 : 8);
        if (ro.isEmpty) break;
        await _ot(
          context,
          YozmaImtihonEkrani(
            topshiriqlar: ro,
            sarlavha: "${kun + 1}-kun — o'zbekchadan arabchaga",
            jumla: !_lugatli,
          ),
        );

      case Vazifa.takror:
        if (takror.isEmpty) break;
        if (_lugatli) {
          await _ot(
            context,
            YozmaImtihonEkrani(
              topshiriqlar: _yozma(takror.take(30).toList(), 999),
              sarlavha: 'Oraliqli takrorlash',
            ),
          );
        } else {
          await _ot(
            context,
            MashqEkran(
              sarlavha: 'Oraliqli takrorlash',
              darsniki: takror.take(20).toList(),
              oldingilar: reja.hammaElement,
            ),
          );
        }

      case Vazifa.gap:
        bajarildi = await _gap(context);
    }

    if (olchov.isNotEmpty) {
      final kerak = max(1, min(olchov.length, 20) ~/ 2);
      bajarildi = _urinish(olchov) - oldin >= kerak;
      if (!bajarildi && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Qadam belgilanmadi — mashqni oxirigacha (yoki kamida yarmini) "
              "bajaring. O'zingiz belgilamoqchi bo'lsangiz, katakchani bosing.",
            ),
          ),
        );
      }
    }
    if (bajarildi) await x.belgila(reja, kun, vazifa, true);
  }

  static List<YozmaTopshiriq> _yozma(List<MashqElement> els, int max) {
    final ro = <YozmaTopshiriq>[];
    for (final e in els) {
      final sozmi = !e.ar.contains(' ');
      if (max == 999 && !sozmi) continue; // so'z rejimida faqat so'zlar
      ro.add(YozmaTopshiriq(uz: e.uz, ar: e.ar, kalit: e.kalit));
      if (max == 999) {
        for (final pl in e.plShakllari) {
          if (!pl.contains(' ')) {
            ro.add(
              YozmaTopshiriq(uz: "${e.uz} — KO'PLIGI", ar: pl, kalit: e.kalit),
            );
          }
        }
      }
      if (ro.length >= max) break;
    }
    return ro;
  }

  Future<bool> _gap(BuildContext context) async {
    final rnd = Random();
    if (_lugatli) {
      // Bugungi so'zlar qatnashgan kitob jumlalari birinchi.
      final bugungi = {for (final e in yangi) stripDiacritics(e.ar)};
      final hammasi = <BoshJoy>[
        for (final d in darslar)
          if (d.qiroat != null) ...BoshJoy.yasa(d.qiroat!),
      ];
      final mos =
          hammasi
              .where(
                (b) => bugungi.contains(
                  stripDiacritics(splitForms(b.lugat.ar).first),
                ),
              )
              .toList()
            ..shuffle(rnd);
      final royxat = [
        ...mos,
        ...(hammasi.where((b) => !mos.contains(b)).toList()..shuffle(rnd)),
      ].take(15).toList();
      if (royxat.isNotEmpty) {
        await _ot(
          context,
          BoshJoyEkrani.royxat(
            royxat: royxat,
            sarlavha: "Jumlada toping — ${kun + 1}-kun",
          ),
        );
        return true;
      }
      // Jumlasi yo'q dars — gap tuzishga o'tamiz.
      final juftlar = <(String, String)>[];
      for (final d in darslar) {
        final l = d.qiroat;
        if (l == null) continue;
        final ar = splitSentences(l.reading);
        final uz = splitSentences(l.translation);
        for (var i = 0; i < ar.length; i++) {
          if (GapTuzish.sozlar(ar[i]).length >= 3) {
            juftlar.add((ar.length == uz.length ? uz[i] : '', ar[i]));
          }
        }
      }
      if (juftlar.isEmpty) return true;
      juftlar.shuffle(rnd);
      if (!context.mounted) return false;
      await _ot(
        context,
        GapTuzishEkrani(juftlar: juftlar.take(10).toList(), tinglab: true),
      );
      return true;
    }
    // Faqat toza misol jumlalari: qo'shtirnoqli tushuntirish matnlari
    // tugmalarga bo'linganda chalkash chiqadi.
    bool toza(String ar) {
      final n = GapTuzish.sozlar(ar).length;
      return n >= 3 && n <= 9 && !RegExp('[«»"():]').hasMatch(ar);
    }

    final juftlar = <(String, String)>[
      for (final e in yangi)
        if (toza(e.ar)) (e.uz, e.ar),
    ]..shuffle(rnd);
    if (juftlar.isNotEmpty) {
      await _ot(
        context,
        GapTuzishEkrani(
          juftlar: juftlar.take(10).toList(),
          title: 'Tinglab gap tuzish',
          tinglab: true,
        ),
      );
    } else if (yangi.isNotEmpty) {
      await _ot(
        context,
        MashqEkran(
          sarlavha: 'Qo\'llash',
          darsniki: yangi,
          oldingilar: reja.hammaElement,
        ),
      );
    }
    return true;
  }
}

// ---------------------------------------------------------------------
// Bugungi so'zlar + ilgak yozish
// ---------------------------------------------------------------------

/// Bugungi so'zlar ro'yxati. [ilgakRejimi]da har so'z tagida o'quvchi o'zi
/// to'qigan ilgak/sahnani yozadi — ilova o'zidan ilgak O'YLAB CHIQARMAYDI
/// (o'zingiz topgan bog'lanish eng kuchli eslanadi, begona sahna esa
/// xato talaffuzni o'rgatib qo'yishi mumkin).
class KunSozlariEkrani extends StatefulWidget {
  final List<MashqElement> sozlar;
  final bool ilgakRejimi;
  final String sarlavha;
  const KunSozlariEkrani({
    super.key,
    required this.sozlar,
    required this.ilgakRejimi,
    required this.sarlavha,
  });

  @override
  State<KunSozlariEkrani> createState() => _KunSozlariEkraniState();
}

class _KunSozlariEkraniState extends State<KunSozlariEkrani> {
  late final Map<String, TextEditingController> _c = {
    for (final e in widget.sozlar)
      e.kalit: TextEditingController(
        text: RejaXotira.instance.ilgaklar[e.kalit] ?? '',
      ),
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saqla() async {
    for (final e in widget.sozlar) {
      final t = _c[e.kalit]!.text;
      if (t.trim() != (RejaXotira.instance.ilgaklar[e.kalit] ?? '')) {
        await RejaXotira.instance.ilgakYoz(e.kalit, t);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sozlar;
    final yozilgan = widget.ilgakRejimi
        ? s.where((e) => _c[e.kalit]!.text.trim().isNotEmpty).length
        : 0;
    return PopScope(
      onPopInvokedWithResult: (_, __) => _saqla(),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.sarlavha)),
        body: _markaz([
          _karta(
            chegara: AppColors.gold.withValues(alpha: 0.6),
            child: Text(
              widget.ilgakRejimi
                  ? "1) So'zni eshiting.  2) Tovushi o'zbekcha (yoki boshqa tanish) "
                        "qaysi so'zga o'xshaydi? Mukammal qofiya shart emas — birinchi "
                        "bo'g'in yetadi.  3) O'sha tanish so'z bilan MA'NONI bitta g'alati, "
                        "katta, harakatli sahnada ko'z oldingizga keltiring va qisqa yozing. "
                        "Kulgili yoki bo'lishi mumkin bo'lmagan sahna yaxshiroq eslanadi."
                  : "Bugun ${s.length} ta so'z — hajm aniq. Har birini eshiting, "
                        "ma'nosini va ko'pligini ko'ring. Hozir yodlashga urinmang — "
                        "faqat tushunib oling; yodlash keyingi qadamlarda.",
              style: TextStyle(color: AppColors.ink, height: 1.45),
            ),
          ),
          const SizedBox(height: 12),
          for (final (i, e) in s.indexed) ...[
            _SozKartasi(
              raqam: i + 1,
              e: e,
              ilgak: widget.ilgakRejimi ? _c[e.kalit] : null,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              await _saqla();
              if (context.mounted) Navigator.pop(context, true);
            },
            icon: const Icon(Icons.check_rounded),
            label: Text(
              widget.ilgakRejimi
                  ? 'Tayyor ($yozilgan / ${s.length} ilgak)'
                  : "Ko'rib chiqdim",
            ),
          ),
        ]),
      ),
    );
  }
}

class _SozKartasi extends StatelessWidget {
  final int raqam;
  final MashqElement e;
  final TextEditingController? ilgak;
  final VoidCallback onChanged;
  const _SozKartasi({
    required this.raqam,
    required this.e,
    required this.ilgak,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _karta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '$raqam',
                style: TextStyle(
                  color: AppColors.matn3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Eshitish',
                onPressed: () => Tts.instance.speak(e.ovoz, id: e.kalit),
                icon: const Icon(Icons.volume_up_rounded),
                color: AppColors.emerald,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        e.ar,
                        style: AppTheme.arabic(size: 28, w: FontWeight.w700),
                      ),
                    ),
                    if (e.pl.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "ko'pligi:",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.matn3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                e.pl,
                                style: AppTheme.arabic(
                                  size: 19,
                                  color: AppColors.matn2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            e.uz,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          if (ilgak != null) ...[
            const SizedBox(height: 8),
            TextField(
              controller: ilgak,
              onChanged: (_) => onChanged(),
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Tovushi … ga o\'xshaydi; sahna: …',
                prefixIcon: const Icon(Icons.link_rounded, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =====================================================================
// 2. XARITA VA REJA
// =====================================================================

class _XaritaQismi extends StatelessWidget {
  final VoidCallback rejaBoshlandi;
  const _XaritaQismi({required this.rejaBoshlandi});

  @override
  Widget build(BuildContext context) {
    final kitoblar = KitobXarita.hammasi();
    final lugat = kitoblar.fold(0, (s, k) => s + k.lugat);
    final koplik = kitoblar.fold(0, (s, k) => s + k.koplik);
    final darslar = kitoblar.fold(0, (s, k) => s + k.darslar.length);
    final qoida = kitoblar
        .where((k) => !k.lugatKitobi)
        .fold(0, (s, k) => s + k.qoida);
    final jadval = kitoblar
        .where((k) => k.lugatKitobi)
        .fold(0, (s, k) => s + k.qoida);

    return _markaz([
      _karta(
        chegara: AppColors.gold.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Butun ilova — hajm',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Son(son: '${kitoblar.length}', nom: 'kitob'),
                _Son(son: '$darslar', nom: 'dars'),
                _Son(son: '$lugat', nom: "lug'at"),
                _Son(son: '$koplik', nom: "ko'plik"),
                _Son(son: '$qoida', nom: 'qoida darsi'),
                _Son(son: '$jadval', nom: 'grammatika jadvali'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "«Ko'p» emas, aniq son: hajmni bilgan odam rejani tuza oladi. "
              "Kitobni tanlab, muddatni belgilang.",
              style: TextStyle(color: AppColors.matn2, fontSize: 13),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      for (final k in kitoblar) ...[
        _KitobKartasi(kitob: k, rejaBoshlandi: rejaBoshlandi),
        const SizedBox(height: 10),
      ],
    ]);
  }
}

class _Son extends StatelessWidget {
  final String son;
  final String nom;
  const _Son({required this.son, required this.nom});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.softGreen,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(
          son,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.zumradMatn,
          ),
        ),
        Text(nom, style: TextStyle(fontSize: 11.5, color: AppColors.matn2)),
      ],
    ),
  );
}

class _KitobKartasi extends StatelessWidget {
  final KitobXarita kitob;
  final VoidCallback rejaBoshlandi;
  const _KitobKartasi({required this.kitob, required this.rejaBoshlandi});

  @override
  Widget build(BuildContext context) {
    final k = kitob;
    final reja = RejaXotira.instance.reja(k.id);
    final d = k.darslar.length;
    final ortacha = k.lugatKitobi ? (k.lugat / d).toStringAsFixed(1) : '';
    return _karta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 38,
                decoration: BoxDecoration(
                  color: k.rang,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  k.nom,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  k.nomAr,
                  style: AppTheme.arabic(size: 16, color: k.rang),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            k.lugatKitobi
                ? "$d dars  ·  ${k.lugat} lug'at (${k.koplik} tasida ko'plik)"
                      "${k.qoida > 0 ? "  ·  ${k.qoida} grammatika jadvali" : ""}\n"
                      "1 darsda o'rtacha $ortacha so'z"
                : '$d dars  ·  ${k.qoida} qoida',
            style: TextStyle(color: AppColors.matn2, height: 1.4, fontSize: 13.5),
          ),
          if (reja != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '✅ Reja bor: ${_oy(reja.kunlar)}, ${reja.tugaganKunlar}/${reja.kunlar} kun',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KitobDarslariEkrani(kitob: k),
                  ),
                ),
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: const Text('Darslar xaritasi'),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final boshlandi = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RejaTuzishEkrani(kitob: k),
                    ),
                  );
                  if (boshlandi == true) rejaBoshlandi();
                },
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text(reja == null ? 'Reja tuzish' : 'Rejani o\'zgartirish'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kitobning har darsi: nechta lug'at, ko'plik, qoida.
class KitobDarslariEkrani extends StatelessWidget {
  final KitobXarita kitob;
  const KitobDarslariEkrani({super.key, required this.kitob});

  @override
  Widget build(BuildContext context) {
    final k = kitob;
    return Scaffold(
      appBar: AppBar(title: Text(k.nom)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 30),
            itemCount: k.darslar.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final d = k.darslar[i];
              final izoh = k.lugatKitobi
                  ? [
                      "${d.lugat} lug'at",
                      if (d.koplik > 0) "${d.koplik} ko'plik",
                      if (d.qoida > 0) '${d.qoida} jadval',
                    ].join(' · ')
                  : '1 qoida · ${d.elementlar().length} misol';
              return Material(
                color: AppColors.karta,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: Text(
                    d.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(izoh),
                  trailing: k.lugatKitobi
                      ? CircleAvatar(
                          backgroundColor: k.rang.withValues(alpha: 0.14),
                          child: Text(
                            '${d.lugat}',
                            style: TextStyle(
                              color: k.rang,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => d.sahifa()),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Muddat tanlash: variantlar jadvali + «kuniga nechta» surgichi.
class RejaTuzishEkrani extends StatefulWidget {
  final KitobXarita kitob;
  const RejaTuzishEkrani({super.key, required this.kitob});

  @override
  State<RejaTuzishEkrani> createState() => _RejaTuzishEkraniState();
}

class _RejaTuzishEkraniState extends State<RejaTuzishEkrani> {
  static const _muddatlar = [14, 30, 45, 60, 90, 120, 180];
  late int _kunlar = _boshlangich();

  KitobXarita get k => widget.kitob;
  int get _birlik => k.lugatKitobi ? _elementSoni : k.darslar.length;

  /// Rejada kunlarga bo'linadigan so'zlar (takrorlanganlar bir marta).
  late final int _elementSoni = k.lugatKitobi
      ? k.darslar.fold(0, (s, d) => s + d.elementlar().length)
      : 0;

  int _boshlangich() {
    final b = widget.kitob.lugatKitobi
        ? widget.kitob.lugat
        : widget.kitob.darslar.length;
    return b >= 30 ? 30 : max(1, b);
  }

  String get _birlikNomi => k.lugatKitobi ? "so'z" : 'dars';

  double _kunlik(int kunlar) => _birlik / kunlar;

  /// Surgich: kuniga nechta birlik (so'z yoki dars).
  int get _kuniga => (_birlik / _kunlar).ceil().clamp(1, _maxKuniga);
  int get _maxKuniga => max(2, min(_birlik, k.lugatKitobi ? 120 : 10));

  /// «kuniga ~29 so'z · 1–2 dars» — kasr emas, butun son.
  String _kunlikMatn(int kunlar) {
    final x = _kunlik(kunlar);
    final n = x >= 10 ? '${x.round()}' : x.toStringAsFixed(1).replaceAll('.0', '');
    if (!k.lugatKitobi) {
      return x >= 1 ? 'kuniga ~$n dars (qoida)' : 'haftasiga ~${(x * 7).round()} dars (qoida)';
    }
    final dars = k.darslar.length / kunlar;
    final d = dars >= 1
        ? '${dars.toStringAsFixed(1).replaceAll('.0', '')} dars'
        : 'haftasiga ~${(dars * 7).round()} dars';
    return "kuniga ~$n so'z · $d";
  }

  /// Taxminiy vaqt: lug'at — so'z boshiga ~1,5 daqiqa (7 qadam bilan);
  /// qoida — dars boshiga ~20 daqiqa. Takrorlash ~20% qo'shadi.
  int _daqiqa(int kunlar) {
    final x = _kunlik(kunlar);
    return ((k.lugatKitobi ? x * 1.5 : x * 20) * 1.2).round();
  }

  @override
  Widget build(BuildContext context) {
    final mavjud = RejaXotira.instance.reja(k.id);
    final variantlar = _muddatlar.where((m) => m <= _birlik).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Reja — ${k.nom}')),
      body: _markaz([
        _karta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hajm',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                k.lugatKitobi
                    ? "${k.darslar.length} dars · ${k.lugat} lug'at "
                          "(${k.koplik} tasida ko'plik) · ${k.qoida} grammatika jadvali.\n"
                          "Yodlanadigan so'z (takrorlanganlar bir marta): $_elementSoni"
                    : '${k.darslar.length} dars · ${k.qoida} qoida',
                style: TextStyle(color: AppColors.matn2, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Qancha muddatda tugatasiz?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        for (final m in variantlar)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: _kunlar == m
                  ? k.rang.withValues(alpha: 0.12)
                  : AppColors.karta,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _kunlar = m),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _kunlar == m
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: k.rang,
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 78,
                        child: Text(
                          _oy(m),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${_kunlikMatn(m)}  ·  ~${_daqiqa(m)} daqiqa',
                          style: TextStyle(color: AppColors.matn2, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        _karta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yoki o\'zingiz tanlang: kuniga nechta $_birlikNomi?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Slider(
                value: _kuniga.toDouble(),
                min: 1,
                max: _maxKuniga.toDouble(),
                divisions: max(1, _maxKuniga - 1),
                label: '$_kuniga $_birlikNomi',
                onChanged: (v) => setState(
                  () => _kunlar = (_birlik / v.round()).ceil(),
                ),
              ),
              Text(
                '${_kunlikMatn(_kunlar)} — ${_oy(_kunlar)}da tugatasiz '
                '(${_sana(Reja.bugun() + _kunlar - 1)} gacha), '
                'kuniga taxminan ${_daqiqa(_kunlar)} daqiqa.',
                style: TextStyle(color: AppColors.ink, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _karta(
          chegara: AppColors.gold.withValues(alpha: 0.6),
          child: Text(
            "💡 Minimal planka: eng YOMON kuningizda ham bajara oladigan "
            "hajmni tanlang. Haftada 2 kun ko'p ishlagandan har kuni oz ishlash "
            "kuchliroq — bardavomlik intensivlikdan ustun.",
            style: TextStyle(color: AppColors.ink, height: 1.45, fontSize: 13.5),
          ),
        ),
        if (mavjud != null) ...[
          const SizedBox(height: 10),
          Text(
            "Diqqat: bu kitobda ${_oy(mavjud.kunlar)}lik reja bor "
            "(${mavjud.tugaganKunlar} kun bajarilgan). Yangi reja uni almashtiradi; "
            "so'zlarni yodlaganingiz saqlanadi.",
            style: TextStyle(color: AppColors.coral, fontSize: 13),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () async {
            await RejaXotira.instance.boshla(k.id, _kunlar);
            if (context.mounted) Navigator.pop(context, true);
          },
          icon: const Icon(Icons.flag_rounded),
          label: Text('Rejani boshlash — ${_oy(_kunlar)}'),
        ),
      ]),
    );
  }
}

// =====================================================================
// 3. USULLAR
// =====================================================================

class _UsullarQismi extends StatelessWidget {
  const _UsullarQismi();

  static const _bolimlar = <(String, String, List<String>)>[
    (
      '🧱',
      '3 asosiy tamoyil',
      [
        "Struktura — avval hajmni bil: «ko'p/kam» emas, aniq son. Hajm ko'rinsa, reja tuziladi.",
        "Konkretlik — mavhum narsa eslanmaydi. So'zning ma'nosini, qayerda ishlatilishini tushunib, ko'z oldingizga keltiring.",
        "Bog'lash — yangi ma'lumotni eski bilimga ilgakdek iling. Ilgaksiz kurtka yerga tushadi.",
      ],
    ),
    (
      '🪜',
      '7 qadamli algoritm (kunlik cheklist shu)',
      [
        "1. Ma'no — so'z nimani anglatadi, qaysi kontekstda.",
        "2. Ilgak — begona tovushni tanish tovushga ulang (birinchi bo'g'in yetadi).",
        "3. Obraz — tovush va ma'no BITTA kadrda: katta, harakatli, g'alati, hissiyotli.",
        "4. Qaramasdan eslash — yoping, ayting, keyin tekshiring. Tanish ≠ eslash.",
        "5. Ikkinchi tomon — o'zbekchasidan arabchasini chiqarish: tushunishdan gapirishga o'tish.",
        "6. Oraliqli takror — unutish boshlanayotganda qaytarish; yaxshi bilingan so'z kamroq keladi.",
        "7. Qo'llash — so'zni jumlada ko'ring, eshiting, ishlating. Faol ishlatilgan so'z qoladi.",
      ],
    ),
    (
      '📈',
      'Unutish egri chizig\'i va oraliqlar',
      [
        "Yangi ma'lumot birinchi kunlarda tez unutiladi — takror aynan shu paytda eng foydali.",
        "Ilova oraliqlari: 1, 2, 4, 7, 14, 30 kun. Xato qilsangiz, so'z qisqa oraliqqa qaytadi.",
        "Bir kunda ezib takrorlashdan ko'ra oraliqlar bilan takrorlash ancha kuchli.",
      ],
    ),
    (
      '🔗',
      'Intizom: minimal planka va zanjir',
      [
        "Har kuni oz — haftada bir kun ko'pdan yaxshi.",
        "Planka shunday bo'lsinki, eng yomon kuningizda ham bajara olasiz. Odat bo'lgach oshirasiz.",
        "Zanjirni uzmang: bitta kichik ish ham kunni saqlab qoladi.",
        "Ishtiyoq keladi va ketadi; odat qoladi.",
      ],
    ),
    (
      '🙂',
      'Xato — signal, qo\'rquv — to\'siq',
      [
        "Xato «shu joyni takrorla» degan belgi, xolos.",
        "Xavotir va qo'rquv yangi ma'lumot kirishini sekinlashtiradi (affektiv filtr). Bola qo'rqmagani uchun tez o'rganadi.",
        "Mukammallik shart emas — maqsad yetarli darajada tushunish va ishlatish.",
      ],
    ),
    (
      '⏱️',
      'Diqqat va energiya',
      [
        "Taymer bilan ishlang: 25 daqiqa ish / 5 daqiqa dam (yoki 15/3, 50/10) — o'zingizga mosini sinab toping.",
        "Diqqatni o'g'irlaydigan narsani aniqlang (ko'pincha telefon va shovqin) va olib tashlang.",
        "Holsizlik — dangasalikning asosiy sababi: uyqu, ovqat, harakat tartibga kelsa, o'qish ham yengillashadi.",
        "Uyqu — xotira mustahkamlanadigan vaqt: kunlik rejani bajarib, yangisini ertaga boshlash foydali.",
      ],
    ),
  ];

  /// Davronbek Turdievning video darslari (YouTube).
  static const _videolar = <(String, String, String)>[
    ('Wc7p4NgO_SU', "Xorijiy so'zlarni yodlashning ko'pchilik bilmaydigan usuli", '4 daq'),
    ('dR-Q07BhKj8', 'Bir qarashda eslab qolish mumkinmi? 3 prinsip', '12 daq'),
    ('n1MI3p0KpzY', "Chet tili so'zlarini eslab qolishning 7 qadamli algoritmi", '42 daq'),
    ('fyxL4D1WF9M', "Til o'rganishda orqaga tortayotgan 9 ta xato", '59 daq'),
    ('ruaSbmL9ErE', 'Xotirani kuchaytirish — 30 daqiqalik amaliy dars', '33 daq'),
    ('hX_L9p8ZEIg', "1 kunda 1000 ta so'z yodlash rostdan ham mumkinmi?", '9 daq'),
  ];

  @override
  Widget build(BuildContext context) {
    return _markaz([
      _karta(
        chegara: AppColors.coral.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📺', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mnemonika darsliklari',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Mnemonika nima ekanini tushunmagan bo'lsangiz — shu videolardan "
              "boshlang. Tavsiya: avval 3-video (7 qadamli algoritm).",
              style: TextStyle(color: AppColors.matn2, fontSize: 13),
            ),
            const SizedBox(height: 8),
            for (final (i, (id, nom, vaqt)) in _videolar.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.coral.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.coral,
                  ),
                ),
                title: Text(
                  '${i + 1}. $nom',
                  style: TextStyle(color: AppColors.ink, fontSize: 14),
                ),
                subtitle: Text('YouTube · $vaqt'),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => launchUrl(
                  Uri.parse('https://youtu.be/$id'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      for (final (ikon, nom, bandlar) in _bolimlar) ...[
        _karta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(ikon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      nom,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final b in bandlar)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    b.startsWith(RegExp(r'\d')) ? b : '•  $b',
                    style: TextStyle(color: AppColors.ink, height: 1.45),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
      Text(
        "Manba: Davronbek Turdievning xotira va til o'rganish bo'yicha video "
        "darslari (qisqacha mazmun, ilova tili bilan).",
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.matn3, fontSize: 12),
      ),
    ]);
  }
}
