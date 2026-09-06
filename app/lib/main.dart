import 'dart:async';

import 'package:flutter/material.dart';
import 'content.dart';
import 'progress.dart';

import 'services/content_updater.dart';
import 'services/tts.dart';
import 'services/vocab_audio.dart';
import 'theme.dart';
import 'screens/home.dart';

late final ContentRepository repo;
late final Progress progress;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  repo = ContentRepository();
  progress = Progress();
  await repo.load();
  await progress.load();
  // Ovozni oldindan sozlaymiz — tugma bosilganda kutish bo'lmasin
  // (telefon brauzerlari kutishdan keyingi ovozni bloklaydi).
  await VocabAudio.instance.load(); // tayyor ovozlar ro'yxati
  unawaited(Tts.instance.init());
  // Yangi darslar saytga qo'shilgan bo'lsa, orqa fonda yuklab qo'yamiz.
  // Ilovani kutdirmaydi; yangisi keyingi ochilishda ko'rinadi.
  unawaited(ContentUpdater.instance.checkForUpdate());
  runApp(const ArabApp());
}

class ArabApp extends StatelessWidget {
  const ArabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Arab tilini oson o'rganamiz",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
