import 'package:flutter/material.dart';

import '../main.dart';
import 'alifbo_home.dart';
import 'lesson/lesson_flow.dart';
import 'nahv_home.dart';
import 'sarf_home.dart';

/// Oxirgi ochilgan darsning ekrani — «Davom etish» uchun.
///
/// Dars topilmasa (kontent o'zgargan bo'lsa) `null`: banner chiqmaydi,
/// xato ham chiqmaydi.
Widget? oxirgiDarsEkrani() {
  final modul = progress.oxirgiModul;
  final id = progress.oxirgiDarsId;
  if (modul == null || id == null || id.isEmpty) return null;
  return darsEkrani(modul, id);
}

/// Modul va dars kalitidan ekran — «Davom etish» va manzil (`#/modul/id`)
/// ikkalasi shu yerdan foydalanadi. Topilmasa `null`.
Widget? darsEkrani(String modul, String id) {
  if (id.isEmpty) return null;
  switch (modul) {
    case 'alifbo':
      return alifboDarsEkrani(id);
    case 'qiroat':
      for (final l in repo.qiroatLessons) {
        if (l.completionId == id) return LessonFlow(lesson: l);
      }
    case 'nahv':
      for (final l in repo.nahvLessons) {
        if ('nahv-${l.book}-${l.num}' == id) {
          return NahvLessonScreen(lesson: l);
        }
      }
    case 'sarf':
      for (final l in repo.sarfLessons) {
        if (l.completionId == id) return SarfLessonScreen(lesson: l);
      }
  }
  return null;
}
