import 'dart:async';

import 'package:flutter/material.dart';
import 'content.dart';
import 'mavzu.dart';
import 'progress.dart';
import 'mashq/tovush.dart';
import 'services/manzil.dart';
import 'services/xabar.dart';
import 'screens/davom.dart';

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
  await Tovush.load(); // mashq tovushlari yoqilgan/o'chiq
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

/// Ilova `#/modul/id` manzili bilan ochilgan bo'lsa (yangilash yoki
/// havola), bosh ekran ustiga o'sha dars bir marta ochiladi. Kirish
/// darvozasidan KEYIN turadi — kodsiz darsga o'tib bo'lmaydi.
class BoshlangichManzil extends StatefulWidget {
  final Widget child;
  const BoshlangichManzil({super.key, required this.child});

  @override
  State<BoshlangichManzil> createState() => _BoshlangichManzilState();
}

class _BoshlangichManzilState extends State<BoshlangichManzil> {
  static bool _ochildi = false;

  @override
  void initState() {
    super.initState();
    if (_ochildi) return;
    _ochildi = true;
    final m = Manzil.boshlangich();
    if (m == null) return;
    final ekran = darsEkrani(m.$1, m.$2);
    if (ekran == null) {
      Manzil.tozala();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ekran));
      // Flutter ishga tushganda manzilni «/» qilib qo'yadi — darsni
      // ochgach uni qaytaramiz, aks holda yangilash bosh ekranga olib boradi.
      Manzil.yangila(m.$1, m.$2);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
        navigatorObservers: [ManzilKuzatuvchi()],
        theme: AppTheme.light,
        home: KirishDarvozasi(
          kod: kirishKodi,
          kerak: darvozaKerak,
          child: const BoshlangichManzil(child: HomeScreen()),
        ),
      ),
    );
  }
}
