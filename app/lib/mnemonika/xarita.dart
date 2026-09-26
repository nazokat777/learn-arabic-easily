import 'package:flutter/material.dart';

import '../content.dart';
import '../main.dart';
import '../mashq/bank.dart';
import '../mashq/element.dart';
import '../screens/lesson/lesson_flow.dart';
import '../screens/nahv_home.dart';
import '../screens/sarf_home.dart';

/// Kitobning bitta darsi — xaritadagi eng kichik birlik.
///
/// Sonlar kontentdan HISOBLANADI (qo'lda yozilmaydi): kitobga yangi dars
/// qo'shilsa, xarita ham o'zi yangilanadi.
class DarsBirlik {
  final String id; // progress'dagi dars id'si (completionId)
  final String nom;
  final String nomAr;

  /// Kitob lug'atidagi yozuvlar soni (dars jadvali qanday bo'lsa).
  final int lugat;

  /// Lug'atdagi ko'plik shakli berilgan so'zlar.
  final int koplik;

  /// Qoida / grammatika birligi: Qiroatda — grammatika jadvali,
  /// Nahv va Sarfda — darsning o'zi bitta qoida.
  final int qoida;

  /// Yodlanadigan elementlar (mashq kalitlari progress bilan umumiy).
  final List<MashqElement> Function() elementlar;

  /// Darsni ochadigan sahifa.
  final Widget Function() sahifa;

  /// Qiroat darsi bo'lsa — jumla mashqlari (bo'sh joy, gap tuzish) uchun.
  final QiroatLesson? qiroat;

  const DarsBirlik({
    required this.id,
    required this.nom,
    required this.nomAr,
    required this.lugat,
    required this.koplik,
    required this.qoida,
    required this.elementlar,
    required this.sahifa,
    this.qiroat,
  });
}

/// Bitta kitob: darslari va jamlanma sonlari.
class KitobXarita {
  final String id; // 'qiroat-1', 'nahv-3', 'sarf'
  final String nom;
  final String nomAr;
  final Color rang;

  /// Qiroat — so'z bo'yicha bo'linadi; Nahv/Sarf — dars (qoida) bo'yicha.
  final bool lugatKitobi;
  final List<DarsBirlik> darslar;

  const KitobXarita({
    required this.id,
    required this.nom,
    required this.nomAr,
    required this.rang,
    required this.lugatKitobi,
    required this.darslar,
  });

  int get lugat => darslar.fold(0, (s, d) => s + d.lugat);
  int get koplik => darslar.fold(0, (s, d) => s + d.koplik);
  int get qoida => darslar.fold(0, (s, d) => s + d.qoida);

  /// Rejada kunlarga bo'linadigan birliklar soni.
  int get birlik => lugatKitobi ? lugat : darslar.length;

  static List<KitobXarita>? _kesh;

  /// Ilovadagi hamma kitoblar, o'qish tartibida.
  static List<KitobXarita> hammasi() => _kesh ??= _yasa();

  static KitobXarita? top(String id) {
    for (final k in hammasi()) {
      if (k.id == id) return k;
    }
    return null;
  }

  static List<KitobXarita> _yasa() {
    const qiroatRang = Color(0xFF1B8A9E);
    const nahvRang = Color(0xFFE0603A);
    const sarfRang = Color(0xFF5B5BD6);
    final natija = <KitobXarita>[];

    for (final b in [1, 2, 3]) {
      final darslar = [
        for (final l in repo.qiroatLessons.where((x) => x.book == b))
          DarsBirlik(
            id: l.completionId,
            nom: '${l.num}-dars',
            nomAr: l.titleAr,
            lugat: l.vocab.length,
            koplik: l.vocab.where((v) => v.pl.trim().isNotEmpty).length,
            qoida: l.tables.length,
            elementlar: () => MashqBank.qiroatDars(l),
            sahifa: () => LessonFlow(lesson: l),
            qiroat: l,
          ),
      ];
      if (darslar.isEmpty) continue;
      natija.add(
        KitobXarita(
          id: 'qiroat-$b',
          nom: 'Mabdaul qiroat — $b-kitob',
          nomAr: 'مَبْدَأُ الْقِرَاءَةِ',
          rang: qiroatRang,
          lugatKitobi: true,
          darslar: darslar,
        ),
      );
    }

    for (final b in [1, 2, 3, 4]) {
      final darslar = [
        for (final l in repo.nahvLessons.where((x) => x.book == b))
          DarsBirlik(
            id: 'nahv-${l.book}-${l.num}',
            nom: '${l.num}. ${l.title}',
            nomAr: l.titleAr,
            lugat: 0,
            koplik: 0,
            qoida: 1,
            elementlar: () => MashqBank.nahvDars(l),
            sahifa: () => NahvLessonScreen(lesson: l),
          ),
      ];
      if (darslar.isEmpty) continue;
      natija.add(
        KitobXarita(
          id: 'nahv-$b',
          nom: 'Nahv — $b-kitob',
          nomAr: 'الدُّرُوسُ النَّحْوِيَّةُ',
          rang: nahvRang,
          lugatKitobi: false,
          darslar: darslar,
        ),
      );
    }

    final sarf = [
      for (final l in repo.sarfLessons)
        DarsBirlik(
          id: l.completionId,
          nom: '${l.num}. ${l.title}',
          nomAr: l.titleAr,
          lugat: 0,
          koplik: 0,
          qoida: 1,
          elementlar: () => MashqBank.sarfDars(l),
          sahifa: () => SarfLessonScreen(lesson: l),
        ),
    ];
    if (sarf.isNotEmpty) {
      natija.add(
        KitobXarita(
          id: 'sarf',
          nom: 'Sarf darsligi',
          nomAr: 'دُرُوسُ الصَّرْفِ',
          rang: sarfRang,
          lugatKitobi: false,
          darslar: sarf,
        ),
      );
    }
    return natija;
  }
}

