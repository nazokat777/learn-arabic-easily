import 'package:flutter/material.dart' hide Text;
import '../widgets/uz_text.dart';
import '../main.dart';
import '../mashq/bank.dart';
import '../mashq/mashq_ekran.dart';
import '../theme.dart';
import '../widgets/mastery_badge.dart';
import '../widgets/premium_tile.dart';
import 'vocab_test.dart';
import 'gap_tuzish_ekrani.dart';
import 'word_game.dart';

/// «Mashqlar» — lug'at testi va so'z yasash o'yini (o'rganilgan so'zlarni mustahkamlash).
class MashqlarHome extends StatelessWidget {
  const MashqlarHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mashqlar')),
      body: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _intro(),
            const SizedBox(height: 16),
            _chaqmoqPlitka(context),
            PremiumTile(
              title: 'Gap tuzish',
              subtitle: "O'zbekcha gapni arabcha so'zlardan tuzing",
              icon: Icons.extension_rounded,
              accent: AppColors.indigo,
              onTap: () => gapTuzishniOch(context),
            ),
            _qiyinPlitka(context),
            // Lug'at testi — haqiqiy test, shuning uchun belgisi ham
            // o'zlashtirish belgisi: xatosiz o'tilmaguncha berilmaydi.
            _tile(
              context,
              id: 'vocab_test',
              mastery: true,
              icon: Icons.menu_book_rounded,
              accent: AppColors.emerald,
              title: 'Lug\'at testi',
              sub: 'Arabcha so\'z → o\'zbekcha ma\'no',
              page: const VocabTest(),
            ),
            _tile(
              context,
              id: 'word_game',
              icon: Icons.extension_rounded,
              accent: AppColors.amber,
              title: 'So\'z yasash o\'yini',
              sub: 'Harflardan to\'g\'ri so\'zni tuzing',
              page: const WordGame(),
            ),
          ],
        ),
      ),
    );
  }

  /// Chaqmoq raund — 60 soniya, bekatsiz, 2× ball, rekord bilan.
  /// Havza: o'quvchi allaqachon ko'rgan so'zlar (kamida bir marta to'g'ri
  /// javob berilgan); hali hech narsa ko'rmagan bo'lsa — alifbo va
  /// 1-kitob boshi. Tezkor raundda notanish so'z emas, TEZLIK sinaladi.
  Widget _chaqmoqPlitka(BuildContext context) {
    final rekord = progress.chaqmoqRekord;
    return PremiumTile(
      title: 'Chaqmoq raund',
      subtitle: rekord > 0
          ? "60 soniya · 2× ball · rekord: $rekord ta to'g'ri"
          : '60 soniya · 2× ball · birinchi rekordni qo\'ying',
      icon: Icons.bolt_rounded,
      accent: AppColors.amber,
      onTap: () => chaqmoqRaundiniOch(context),
    );
  }

  /// «Qiyin so'zlarim» — hamma moduldan 3+ marta adashilgan so'zlar.
  ///
  /// Eng tepada turadi: o'quvchi nimada qoqilayotganini qidirib
  /// yurmasin, ilova o'zi ko'rsatib tursin. Ro'yxat bo'sh bo'lsa ham
  /// plitka ko'rinadi — «hozircha qiyin so'z yo'q» ham mukofot.
  Widget _qiyinPlitka(BuildContext context) {
    final soni = progress.qiyinKalitlar.length;
    final bosh = soni == 0;
    return PremiumTile(
      title: bosh ? "Qiyin so'zlarim" : "Qiyin so'zlarim ($soni)",
      subtitle: bosh
          ? "Hozircha yo'q — zo'r ketyapsiz!"
          : "3+ marta adashilgan so'zlar — avval o'rgatiladi, keyin so'raladi",
      icon: Icons.psychology_rounded,
      accent: AppColors.coral,
      trailing: bosh
          ? const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 22,
              ),
            )
          : null,
      onTap: bosh
          ? () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Qiyin so'z yo'q. Mashq qilib turing!"),
              ),
            )
          : () => qiyinMashqiniOch(context),
    );
  }

  Widget _intro() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.softGreen,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(Icons.psychology_rounded, size: 28, color: AppColors.emerald),
        SizedBox(width: 14),
        Expanded(
          child: Text(
            'O\'rgangan so\'zlaringizni test va o\'yin orqali mustahkamlang.',
            style: TextStyle(color: AppColors.ink, height: 1.35),
          ),
        ),
      ],
    ),
  );

  /// [mastery] — belgi o'zlashtirish (xatosiz test) bo'yicha ko'rsatilsinmi.
  /// So'z yasash o'yinida bu ma'nosiz: unda belgilangan savollar to'plami
  /// yo'q, shuning uchun u eski «bajarildi» belgisida qoladi.
  Widget _tile(
    BuildContext context, {
    required String id,
    required IconData icon,
    required Color accent,
    required String title,
    required String sub,
    required Widget page,
    bool mastery = false,
  }) {
    final done = progress.isCompleted(id);
    return PremiumTile(
      title: title,
      subtitle: sub,
      icon: icon,
      accent: accent,
      trailing: mastery
          ? MasteryBadge(lessonId: id, size: 22)
          : done
          ? const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 22,
              ),
            )
          : null,
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}

/// Chaqmoq raundini ochadi: tanish so'zlardan 40 tasi tasodifiy.
void chaqmoqRaundiniOch(BuildContext context) {
  final hammasi = MashqBank.hammasi();
  var havza = hammasi.where((e) => progress.wordMastery(e.kalit) > 0).toList();
  if (havza.length < 12) havza = hammasi.take(60).toList();
  havza.shuffle();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MashqEkran(
        sarlavha: 'Chaqmoq raund',
        darsniki: havza.take(40).toList(),
        oldingilar: const [],
        tezkorSoniya: 60,
      ),
    ),
  );
}

/// «Qiyin so'zlarim» mashqini ochadi — elementlar aynan shu paytda
/// yig'iladi (butun kontentni bir marta aylanib chiqish).
void qiyinMashqiniOch(BuildContext context) {
  final qiyin = MashqBank.qiyinlar();
  if (qiyin.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Qiyin so'z yo'q. Mashq qilib turing!")),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MashqEkran(
        sarlavha: "Qiyin so'zlarim",
        darsniki: qiyin,
        oldingilar: MashqBank.qiyinHavzasi(qiyin),
      ),
    ),
  );
}
