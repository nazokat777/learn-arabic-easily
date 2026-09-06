import 'package:flutter/material.dart' hide Text;
import 'uz_text.dart';

import '../arabic.dart';
import '../content.dart';
import '../theme.dart';
import 'speak_button.dart';

/// Harfning so'z boshida, o'rtasida va oxirida qanday kelishini o'rgatadi.
///
/// Nega alohida bo'lim kerak: boshlang'ich o'quvchi «so'z boshi» degani
/// nima ekanini TUSHUNMAYDI. Sababi bitta va aniq — arabcha o'ngdan
/// chapga yoziladi, ya'ni so'z boshi O'NG tomonda. O'zbek yozuviga
/// o'rgangan ko'z buni o'zi anglamaydi, aytib berish kerak.
///
/// Shuning uchun bo'lim uch qadamdan iborat:
///   1. yo'nalishni tushuntirish (o'ng = bosh, chap = oxir), misol so'zda
///      ko'rsatib;
///   2. har holat uchun harfning SHAKLI;
///   3. o'sha shakl HAQIQIY so'z ichida — so'z harflarga ajratilib,
///      kerakli harf oltin rangda belgilanadi.
///
/// Misol so'zlar o'ylab topilmaydi — ilovaning o'z lug'atidan olinadi.
class HarfHolatiBolimi extends StatelessWidget {
  final Letter letter;

  /// Misol izlanadigan lug'at (qisqa so'zlar oldinda bo'lgani ma'qul).
  final List<({String ar, String uz})> lugat;

  const HarfHolatiBolimi({
    super.key,
    required this.letter,
    required this.lugat,
  });

  @override
  Widget build(BuildContext context) {
    final misollar = harfMisollari(letter.ar, lugat);
    final ulanar = letter.connectsLeft;
    // Yo'nalishni ko'rsatish uchun misol: qaysi biri bo'lsa ham bo'ladi.
    final namuna = misollar.values.isNotEmpty
        ? misollar.values.first.ar
        : letter.ar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "So'zda qayerda turadi?",
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 10),
        _YonalishKarta(namuna: namuna),
        if (!ulanar) ...[
          const SizedBox(height: 10),
          _Eslatma(
            matn:
                "«${letter.nameUz}» o'zidan KEYINGI harfga ulanmaydi — shuning "
                "uchun u so'z boshida ham, o'rtasida ham deyarli bir xil "
                "ko'rinadi va o'zidan keyin zanjir uziladi.",
          ),
        ],
        const SizedBox(height: 14),
        _HolatQatori(
          sarlavha: "So'z BOSHIDA",
          izoh: "eng o'ngdagi harf",
          shakl: letter.initial,
          misol: misollar[SozOrni.boshi],
        ),
        _HolatQatori(
          sarlavha: "So'z O'RTASIDA",
          izoh: 'ikki harf orasida',
          shakl: letter.medial,
          misol: misollar[SozOrni.ortasi],
        ),
        _HolatQatori(
          sarlavha: "So'z OXIRIDA",
          izoh: 'eng chapdagi harf',
          shakl: letter.finalForm,
          misol: misollar[SozOrni.oxiri],
        ),
      ],
    );
  }
}

/// Yo'nalish kartasi — arabchaning o'ngdan chapga yozilishini ko'rsatadi.
class _YonalishKarta extends StatelessWidget {
  final String namuna;
  const _YonalishKarta({required this.namuna});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.45),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Arabcha O'NGDAN CHAPGA yoziladi.\n"
            "Shuning uchun so'z BOSHI — o'ng tomonda, OXIRI — chap tomonda.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.ink, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              namuna,
              style: AppTheme.arabic(size: 40, color: AppColors.emerald),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '← OXIRI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    color: Colors.black45,
                  ),
                ),
              ),
              Text(
                "BOSHI →",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Eslatma extends StatelessWidget {
  final String matn;
  const _Eslatma({required this.matn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        matn,
        style: const TextStyle(
          color: AppColors.ink,
          height: 1.35,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

/// Bitta holat: shakl + tushuntirish + haqiqiy so'z misoli.
class _HolatQatori extends StatelessWidget {
  final String sarlavha;
  final String izoh;
  final String shakl;
  final HarfMisoli? misol;

  const _HolatQatori({
    required this.sarlavha,
    required this.izoh,
    required this.shakl,
    required this.misol,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      shakl,
                      style: AppTheme.arabic(
                        size: 32,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sarlavha,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        izoh,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (misol != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  SpeakButton(
                    text: misol!.ar,
                    id: 'holat-${misol!.ar}',
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        misol!.ar,
                        style: AppTheme.arabic(
                          size: 26,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    misol!.uz,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // So'z harflarga ajratiladi va kerakli harf oltin rangda
              // belgilanadi — o'quvchi uni so'z ichidan KO'RIB topadi.
              // Har harf alohida qutida turadi, shuning uchun shrift
              // ularni ulamaydi va shakl aniq ko'rinadi.
              _AjratilganSoz(soz: misol!.ar, belgi: misol!.index),
            ],
          ],
        ),
      ),
    );
  }
}

class _AjratilganSoz extends StatelessWidget {
  final String soz;

  /// Belgilanadigan bo'lakning indeksi.
  ///
  /// Ataylab indeks, «birinchi mos harf» emas: so'zda bir xil harf ikki
  /// marta kelsa (masalan «بَابٌ» dagi ikki «ب»), noto'g'ri joyi
  /// belgilanib, o'quvchi chalg'irdi.
  final int belgi;

  const _AjratilganSoz({required this.soz, required this.belgi});

  @override
  Widget build(BuildContext context) {
    final bolaklar = splitLetters(soz);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < bolaklar.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: i == belgi
                    ? AppColors.gold.withValues(alpha: 0.18)
                    : AppColors.cream,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: i == belgi ? AppColors.gold : Colors.black12,
                  width: i == belgi ? 1.6 : 1,
                ),
              ),
              child: Text(
                bolaklar[i],
                style: AppTheme.arabic(
                  size: 20,
                  color: i == belgi ? AppColors.gold : AppColors.ink,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
