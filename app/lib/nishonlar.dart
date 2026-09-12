import 'package:flutter/material.dart';

import 'progress.dart';
import 'theme.dart';

/// Nishon (yutuq) — bir marta ochiladigan belgi.
///
/// Nega: to'plam «to'ldirish» istagi (completionism) va kutilmagan
/// «ochildi!» lahzasi — ikkalasi ham kuchli dofamin manbai. Nishonlar
/// o'quvchining REAL ishiga bog'langan: javoblar, yodlangan so'zlar,
/// seriya, maqsad kunlari, kombo, daraja — soxta «kunlik kirish» emas.
class Nishon {
  final String id;
  final String nom;
  final String tavsif;
  final IconData ikon;
  final Color rang;
  final bool Function(Progress p) shart;

  const Nishon({
    required this.id,
    required this.nom,
    required this.tavsif,
    required this.ikon,
    required this.rang,
    required this.shart,
  });
}

/// Barcha nishonlar — tartib: osondan qiyinga, ekranda shu tartibda.
const List<Nishon> nishonlar = [
  Nishon(
    id: 'birinchi-qadam',
    nom: 'Birinchi qadam',
    tavsif: 'Birinchi savolga javob berdingiz',
    ikon: Icons.directions_walk_rounded,
    rang: AppColors.emerald,
    shart: _birinchiQadam,
  ),
  Nishon(
    id: 'javob-100',
    nom: '100 javob',
    tavsif: 'Jami 100 ta savol yechildi',
    ikon: Icons.question_answer_rounded,
    rang: AppColors.teal,
    shart: _javob100,
  ),
  Nishon(
    id: 'javob-500',
    nom: '500 javob',
    tavsif: 'Jami 500 ta savol yechildi',
    ikon: Icons.forum_rounded,
    rang: AppColors.teal,
    shart: _javob500,
  ),
  Nishon(
    id: 'javob-2000',
    nom: 'Mehnatkash',
    tavsif: 'Jami 2000 ta savol yechildi',
    ikon: Icons.workspace_premium_rounded,
    rang: AppColors.gold,
    shart: _javob2000,
  ),
  Nishon(
    id: 'soz-10',
    nom: "10 so'z",
    tavsif: "10 ta so'z to'liq yodlandi",
    ikon: Icons.spellcheck_rounded,
    rang: AppColors.emerald,
    shart: _soz10,
  ),
  Nishon(
    id: 'soz-50',
    nom: "50 so'z",
    tavsif: "50 ta so'z to'liq yodlandi",
    ikon: Icons.menu_book_rounded,
    rang: AppColors.emerald,
    shart: _soz50,
  ),
  Nishon(
    id: 'soz-200',
    nom: "Lug'atboz",
    tavsif: "200 ta so'z to'liq yodlandi",
    ikon: Icons.auto_stories_rounded,
    rang: AppColors.gold,
    shart: _soz200,
  ),
  Nishon(
    id: 'seriya-3',
    nom: 'Uch kun',
    tavsif: '3 kun ketma-ket maqsad bajarildi',
    ikon: Icons.local_fire_department_rounded,
    rang: AppColors.coral,
    shart: _seriya3,
  ),
  Nishon(
    id: 'seriya-7',
    nom: 'Bir hafta',
    tavsif: '7 kun ketma-ket maqsad bajarildi',
    ikon: Icons.local_fire_department_rounded,
    rang: AppColors.coral,
    shart: _seriya7,
  ),
  Nishon(
    id: 'seriya-30',
    nom: 'Bir oy olov',
    tavsif: '30 kun ketma-ket maqsad bajarildi',
    ikon: Icons.whatshot_rounded,
    rang: AppColors.gold,
    shart: _seriya30,
  ),
  Nishon(
    id: 'maqsad-10',
    nom: "10 maqsad kuni",
    tavsif: 'Kunlik maqsad 10 marta bajarildi',
    ikon: Icons.event_available_rounded,
    rang: AppColors.success,
    shart: _maqsad10,
  ),
  Nishon(
    id: 'kombo-10',
    nom: 'Kombo 10',
    tavsif: "Ketma-ket 10 ta to'g'ri javob",
    ikon: Icons.bolt_rounded,
    rang: AppColors.amber,
    shart: _kombo10,
  ),
  Nishon(
    id: 'kombo-25',
    nom: 'Kombo 25',
    tavsif: "Ketma-ket 25 ta to'g'ri javob",
    ikon: Icons.electric_bolt_rounded,
    rang: AppColors.amber,
    shart: _kombo25,
  ),
  Nishon(
    id: 'daraja-3',
    nom: 'Kumush',
    tavsif: '3-darajaga chiqdingiz',
    ikon: Icons.military_tech_rounded,
    rang: AppColors.indigo,
    shart: _daraja3,
  ),
  Nishon(
    id: 'daraja-5',
    nom: 'Oltin',
    tavsif: '5-darajaga chiqdingiz',
    ikon: Icons.emoji_events_rounded,
    rang: AppColors.gold,
    shart: _daraja5,
  ),
  Nishon(
    id: 'dars-5',
    nom: "5 dars o'zlashtirildi",
    tavsif: "5 ta dars xatosiz o'zlashtirildi",
    ikon: Icons.verified_rounded,
    rang: AppColors.success,
    shart: _dars5,
  ),
  Nishon(
    id: 'aniq-90',
    nom: 'Mergan',
    tavsif: "100+ javobda aniqlik 90% dan yuqori",
    ikon: Icons.gps_fixed_rounded,
    rang: AppColors.teal,
    shart: _aniq90,
  ),
  Nishon(
    id: 'sandiq-7',
    nom: 'Xazina izlovchi',
    tavsif: 'Kunlik sandiq 7 marta ochildi',
    ikon: Icons.inventory_2_rounded,
    rang: AppColors.gold,
    shart: _sandiq7,
  ),
];

bool _birinchiQadam(Progress p) => p.jamiJavoblar >= 1;
bool _javob100(Progress p) => p.jamiJavoblar >= 100;
bool _javob500(Progress p) => p.jamiJavoblar >= 500;
bool _javob2000(Progress p) => p.jamiJavoblar >= 2000;
bool _soz10(Progress p) => p.yodlanganSoni >= 10;
bool _soz50(Progress p) => p.yodlanganSoni >= 50;
bool _soz200(Progress p) => p.yodlanganSoni >= 200;
bool _seriya3(Progress p) => p.streak >= 3;
bool _seriya7(Progress p) => p.streak >= 7;
bool _seriya30(Progress p) => p.streak >= 30;
bool _maqsad10(Progress p) => p.maqsadKunlariSoni >= 10;
bool _kombo10(Progress p) => p.rekordKombo >= 10;
bool _kombo25(Progress p) => p.rekordKombo >= 25;
bool _daraja3(Progress p) => p.level >= 3;
bool _daraja5(Progress p) => p.level >= 5;
bool _dars5(Progress p) => p.ozlashtirilganDarslar >= 5;
bool _aniq90(Progress p) => p.jamiJavoblar >= 100 && p.aniqlikFoizi >= 90;
bool _sandiq7(Progress p) => p.sandiqSoni >= 7;

/// Id bo'yicha nishon (yo'q bo'lsa null).
Nishon? nishonTop(String id) {
  for (final n in nishonlar) {
    if (n.id == id) return n;
  }
  return null;
}
