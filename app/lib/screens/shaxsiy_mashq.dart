import 'package:flutter/material.dart' hide Text;
import 'package:http/http.dart' as http;

import '../arabic.dart';
import '../content.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets/uz_text.dart';
import 'aralash_mashq.dart';
import 'davom.dart';
import 'lesson/qiyin_sozlar.dart';

/// O'ZINI MOSLAYDIGAN mashq: har kuni o'quvchining o'z tarixidan tuziladi.
///
/// Shu paytgacha ochilgan Qiroat darslaridagi so'zlardan eng zaiflari
/// (ko'p xato, past daraja, takror vaqti kelgan) va o'zi tanlagan qiyin
/// so'zlar olinadi. Javoblar daraja va xatolarni yangilaydi — ertangi
/// ro'yxat shunga qarab o'zgaradi: yodlangani chiqib ketadi, qiyni qoladi.
class ShaxsiyReja {
  ShaxsiyReja._();

  static const int hajm = 15;

  static ({
    QiroatLesson dars,
    List<QiroatVocab> sozlar,
    Map<String, String> darsIdlar,
  })?
  tuz() {
    final oxirgi = oxirgiQiroatDarsi();
    if (oxirgi == null) return null;
    final chegara = oxirgi.book * 1000 + oxirgi.num;
    final ball = <(double, QiroatVocab, String)>[];
    final korilgan = <String>{};
    for (final l in repo.qiroatLessons) {
      if (l.book * 1000 + l.num > chegara) continue;
      final id = l.completionId;
      final tanlangan = {for (final v in QiyinTanlov.sozlar(id)) v.ar};
      for (final v in [...l.vocab, ...QiyinTanlov.sozlar(id)]) {
        final bosh = splitForms(v.ar).first;
        if (v.uz.trim().isEmpty || bosh.contains(' ')) continue;
        if (!korilgan.add(v.ar)) continue;
        final k = QiyinTanlov.kalit(id, v);
        final yangi = progress.yangiElement(k);
        if (yangi && !tanlangan.contains(v.ar)) continue;
        var b = yangi ? 0.0 : progress.zaiflik(k);
        if (tanlangan.contains(v.ar)) b += 10;
        if (!yangi && progress.keyingiTakrorKun(k) == 0) b += 2;
        if (!yangi && progress.ketmaKetTogri(k) >= QiyinTanlov.yodlandi) {
          b -= 3;
        }
        ball.add((b, v, id));
      }
    }
    if (ball.length < 4) return null;
    ball.sort((a, b) => b.$1.compareTo(a.$1));
    final tanla = ball.take(hajm).toList();
    return (
      dars: oxirgi,
      sozlar: [for (final x in tanla) x.$2],
      darsIdlar: {for (final x in tanla) x.$2.ar: x.$3},
    );
  }
}

class ShaxsiyMashqKarta extends StatelessWidget {
  const ShaxsiyMashqKarta({super.key});

  @override
  Widget build(BuildContext context) {
    final r = ShaxsiyReja.tuz();
    if (r == null) return const SizedBox.shrink();
    return _NeonKarta(
      key: const ValueKey('shaxsiy-mashq'),
      rang: const Color(0xFF06B6D4),
      belgi: Icons.auto_awesome_rounded,
      sarlavha: 'Bugungi shaxsiy mashq',
      izoh:
          "${r.sozlar.length} ta so'z — xatolaringizga qarab har kuni "
          "o'zi moslashadi",
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AralashMashqEkrani(
            lesson: r.dars,
            faqat: r.sozlar,
            darsIdlar: r.darsIdlar,
            sarlavha: 'Shaxsiy mashq',
          ),
        ),
      ),
    );
  }
}

/// Talab va takliflar — ntfy.sh mavzusiga yuboriladi; ishlab chiquvchi
/// ularni muntazam o'qib, ilovani yangilaydi.
class Taklif {
  Taklif._();
  static const mavzu = 'learn-arabic-easily-taklif-7f3k9q';

  static Future<bool> yubor(String matn) async {
    try {
      final r = await http.post(
        Uri.parse('https://ntfy.sh/$mavzu'),
        headers: {'Title': 'Taklif'},
        body: matn,
      );
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}

class TaklifKarta extends StatelessWidget {
  const TaklifKarta({super.key});

  Future<void> _och(BuildContext context) async {
    final ctrl = TextEditingController();
    final yuborildi = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Talab va taklif'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Nima yoqmadi, nima qo'shilsin, qayerda xato bor — yozing. "
              "Ilova shu takliflar asosida yangilanib boradi.",
              style: TextStyle(fontSize: 13, color: AppColors.matn2),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('taklif-matn'),
              controller: ctrl,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Taklifingiz…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Bekor')),
          FilledButton(
            key: const ValueKey('taklif-yubor'),
            onPressed: () async {
              final m = ctrl.text.trim();
              if (m.isEmpty) return;
              final nav = Navigator.of(c);
              nav.pop(await Taklif.yubor(m));
            },
            child: Text('Yuborish'),
          ),
        ],
      ),
    );
    if (yuborildi == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          yuborildi
              ? "Rahmat! Taklifingiz yetib bordi."
              : "Yuborilmadi — internetni tekshirib, qayta urinib ko'ring.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _NeonKarta(
    key: const ValueKey('taklif-karta'),
    rang: const Color(0xFFEC4899),
    belgi: Icons.lightbulb_rounded,
    sarlavha: 'Talab va taklif',
    izoh: "Fikringizni yozing — ilova shunga qarab yaxshilanadi",
    onTap: () => _och(context),
  );
}

class _NeonKarta extends StatelessWidget {
  final Color rang;
  final IconData belgi;
  final String sarlavha;
  final String izoh;
  final VoidCallback onTap;
  const _NeonKarta({
    super.key,
    required this.rang,
    required this.belgi,
    required this.sarlavha,
    required this.izoh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.karta,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: rang.withValues(alpha: 0.55), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: rang.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: rang,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(belgi, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sarlavha,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    izoh,
                    style: TextStyle(fontSize: 12.5, color: AppColors.matn2),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: rang),
          ],
        ),
      ),
    ),
  );
}
