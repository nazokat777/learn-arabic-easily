import 'dart:async';

import 'package:flutter/material.dart';
import 'content.dart';
import 'mavzu.dart';
import 'progress.dart';
import 'services/xabar.dart';

import 'services/content_updater.dart';
import 'services/kirish.dart';
import 'services/tts.dart';
import 'services/vocab_audio.dart';
import 'theme.dart';
import 'uz_yozuv.dart';
import 'screens/home.dart';
import 'screens/kirish_ekrani.dart';

late final ContentRepository repo;
late final Progress progress;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  repo = ContentRepository();
  progress = Progress();
  await repo.load();
  await progress.load();
  await UzYozuv.instance.load(); // lotin yoki kirill
  await Mavzu.instance.load(); // yorug' yoki qorong'u (palitrani ham o'rnatadi)
  // Ovozni oldindan sozlaymiz — tugma bosilganda kutish bo'lmasin
  // (telefon brauzerlari kutishdan keyingi ovozni bloklaydi).
  await VocabAudio.instance.load(); // tayyor ovozlar ro'yxati
  unawaited(Tts.instance.init());
  // Yangi darslar saytga qo'shilgan bo'lsa, orqa fonda yuklab qo'yamiz.
  // Ilovani kutdirmaydi; yangisi keyingi ochilishda ko'rinadi.
  unawaited(ContentUpdater.instance.checkForUpdate());
  // Sayt faqat o'quv guruhi uchun: kod qo'yilgan bo'lsa, darvoza.
  final kirishKodi = await Kirish.kodniOqi();
  final darvozaKerak = await Kirish.kerakmi(kirishKodi);
  runApp(ArabApp(kirishKodi: kirishKodi, darvozaKerak: darvozaKerak));
}

class ArabApp extends StatelessWidget {
  final String kirishKodi;
  final bool darvozaKerak;

  const ArabApp({super.key, this.kirishKodi = '', this.darvozaKerak = false});

  @override
  Widget build(BuildContext context) {
    // Diqqat: yozuv almashtirilganda bu yerdan qayta chizish SHART EMAS —
    // har bir matn vidjeti o'zgarishni o'zi tinglaydi (widgets/uz_text.dart).
    // Mavzu almashganda MaterialApp yangi kalit bilan qayta quriladi —
    // palitra static maydonlarda, shuning uchun butun daraxt yangidan
    // o'qishi kerak.
    return ListenableBuilder(
      listenable: Mavzu.instance,
      builder: (context, _) => MaterialApp(
        key: ValueKey(Mavzu.instance.qorongu),
        title: "Arab tilini oson o'rganamiz",
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: xabarKaliti,
        theme: AppTheme.light,
        home: KirishDarvozasi(
          kod: kirishKodi,
          kerak: darvozaKerak,
          child: const HomeScreen(),
        ),
      ),
    );
  }
}
