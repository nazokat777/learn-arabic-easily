import 'package:flutter/material.dart' hide Text;

import '../arabic.dart';
import '../content.dart';
import '../main.dart';
import '../progress.dart';
import '../mnemonika/reja.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/uz_text.dart';
import 'element.dart';

/// Darsning lug'atini ro'yxat ekranlari uchun elementlarga o'giradi.
/// Kalit — dars oqimidagi (LessonFlow) xotira kaliti bilan bir xil:
/// `<darsId>::<arabcha>`, shuning uchun darajalar to'g'ri ko'rinadi.
List<MashqElement> darsSozlari(QiroatLesson l) {
  final korilgan = <String>{};
  final natija = <MashqElement>[];
  for (final v in l.vocab) {
    final kalit = '${l.completionId}::${v.ar}';
    if (!korilgan.add(kalit)) continue;
    final birinchi = splitForms(v.ar).first.split('=').first.trim();
    natija.add(
      MashqElement(
        kalit: kalit,
        ar: v.ar,
        uz: v.uz,
        darsId: l.completionId,
        tartib: l.book * 1000 + l.num,
        modul: 'Mabdaul qiroat',
        pl: v.pl,
        ovoz: birinchi,
      ),
    );
  }
  return natija;
}

/// So'zning lotincha o'qilishi: tayyor ilgakdagi aniq o'qilish bo'lsa shu,
/// aks holda harakatlardan hisoblangan taxminiy o'qilish.
String talaffuzOf(MashqElement e) {
  final t = RejaXotira.instance.tayyorIlgak(e.ar);
  if (t != null && t.oqilishi.trim().isNotEmpty) return t.oqilishi.trim();
  final birinchi = splitForms(e.ar).first.split('=').first.trim();
  return approxTranslit(birinchi);
}

/// Bitta so'z qatori: ovoz tugmasi, arabcha, o'qilishi, tarjimasi, ko'pligi.
class _SozQatori extends StatelessWidget {
  final int raqam;
  final MashqElement e;
  final Widget? oxiri;
  const _SozQatori({required this.raqam, required this.e, this.oxiri});

  @override
  Widget build(BuildContext context) {
    final oqilish = talaffuzOf(e);
    return Material(
      color: AppColors.karta,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (e.ovoz.isNotEmpty) Tts.instance.speak(e.ovoz, id: e.kalit);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$raqam',
                  style: TextStyle(color: AppColors.matn3, fontSize: 12),
                ),
              ),
              Icon(Icons.volume_up_rounded, color: AppColors.emerald, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          e.ar,
                          style: AppTheme.arabic(
                            size: 26,
                            w: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    if (e.pl.isNotEmpty)
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            e.pl,
                            style: AppTheme.arabic(
                              size: 18,
                              color: AppColors.matn2,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      oqilish,
                      style: TextStyle(
                        color: AppColors.coral,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      e.pl.isNotEmpty ? "${e.uz}  (ko'pligi bor)" : e.uz,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              ?oxiri,
            ],
          ),
        ),
      ),
    );
  }
}

/// YODLASHDAN OLDIN: shu mashqdagi hamma so'zning to'liq ro'yxati —
/// arabcha, o'qilishi (talaffuz), tarjimasi, ko'pligi, ovozi. O'quvchi
/// avval ko'rib, eshitib chiqadi, keyin yodlash boshlanadi.
class SozlarOldindanRoyxat extends StatelessWidget {
  final List<MashqElement> sozlar;
  final VoidCallback onBoshla;
  const SozlarOldindanRoyxat({
    super.key,
    required this.sozlar,
    required this.onBoshla,
  });

  @override
  Widget build(BuildContext context) {
    // Takrorlarni (bir xil kalit) olib tashlaymiz.
    final korilgan = <String>{};
    final royxat = [
      for (final e in sozlar)
        if (korilgan.add(e.kalit)) e,
    ];
    final yangi = royxat.where((e) => progress.yangiElement(e.kalit)).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Avval so'zlar ro'yxati: ${royxat.length} ta",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Har so'zni o'qing, bosib eshiting: arabcha, o'qilishi, "
                  "tarjimasi${yangi > 0 ? " ($yangi tasi yangi)" : ""}. "
                  "Tayyor bo'lgach yodlashni boshlaymiz.",
                  style: TextStyle(
                    color: AppColors.matn2,
                    height: 1.4,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            itemCount: royxat.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _SozQatori(raqam: i + 1, e: royxat[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: AppColors.emerald,
              ),
              onPressed: onBoshla,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Yodlashni boshlash',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// YODLASH OXIRIDA: qaysi so'zlar yaxshi yodlandi, qaysilari yo'q —
/// to'liq ikki ro'yxat (qisqartirilmaydi).
///
/// Mezon: shu mashqda birorta xato qilinmagan VA xotira darajasi kamida
/// 2/5 bo'lsa — «yaxshi yodlandi». Xato bo'lgan yoki daraja past bo'lsa —
/// «yaxshi yodlanmadi» (ustida ishlash kerak).
class SozlarNatijaRoyxati extends StatelessWidget {
  final List<MashqElement> sozlar;
  final Set<String> xatolar;
  const SozlarNatijaRoyxati({
    super.key,
    required this.sozlar,
    required this.xatolar,
  });

  @override
  Widget build(BuildContext context) {
    final korilgan = <String>{};
    final hammasi = [
      for (final e in sozlar)
        if (korilgan.add(e.kalit)) e,
    ];
    if (hammasi.isEmpty) return const SizedBox.shrink();
    bool yaxshi(MashqElement e) =>
        !xatolar.contains(e.kalit) && progress.wordMastery(e.kalit) >= 2;
    final yaxshilar = hammasi.where(yaxshi).toList();
    final yomonlar = hammasi.where((e) => !yaxshi(e)).toList()
      ..sort((a, b) => b.zaiflik.compareTo(a.zaiflik));

    Widget bolim({
      required String sarlavha,
      required String izoh,
      required Color rang,
      required IconData ikon,
      required List<MashqElement> royxat,
    }) {
      if (royxat.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
            child: Row(
              children: [
                Icon(ikon, color: rang, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$sarlavha (${royxat.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: rang,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
            child: Text(
              izoh,
              style: TextStyle(color: AppColors.matn2, fontSize: 12.5),
            ),
          ),
          for (final (i, e) in royxat.indexed) ...[
            _SozQatori(
              raqam: i + 1,
              e: e,
              oxiri: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${progress.wordMastery(e.kalit)}/${Progress.masteryGoal}',
                      style: TextStyle(
                        color: rang,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      xatolar.contains(e.kalit) ? 'xato' : 'xotira',
                      style: TextStyle(color: AppColors.matn3, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bolim(
          sarlavha: "Yaxshi yodlanmadi — ustida ishlash kerak",
          izoh:
              "Shu mashqda adashgan yoki xotira darajasi hali past so'zlar. "
              "Bosib eshiting va takrorlang.",
          rang: AppColors.coral,
          ikon: Icons.replay_circle_filled_rounded,
          royxat: yomonlar,
        ),
        bolim(
          sarlavha: 'Yaxshi yodlandi',
          izoh: "Xatosiz o'tgan va xotirada mustahkamlanayotgan so'zlar.",
          rang: AppColors.success,
          ikon: Icons.check_circle_rounded,
          royxat: yaxshilar,
        ),
      ],
    );
  }
}
