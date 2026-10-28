import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Harf o'lchami — ba'zi o'quvchilarga standart shrift kichik. Tanlov
/// saqlanadi va butun ilovadagi matnga (arabcha ham, o'zbekcha ham)
/// telefonning o'z shrift sozlamasi ustidan ko'paytiriladi.
class HarfOlchami extends ValueNotifier<int> {
  HarfOlchami._() : super(0);
  static final HarfOlchami instance = HarfOlchami._();

  static const _kalit = 'harf_olchami';
  static const darajalar = [1.0, 1.15, 1.3, 1.5];
  static const nomlar = ['Oddiy', 'Katta', 'Kattaroq', 'Eng katta'];

  double get koeff => darajalar[value];
  String get nomi => nomlar[value];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    value = (p.getInt(_kalit) ?? 0).clamp(0, darajalar.length - 1);
  }

  /// Keyingi daraja (oxiridan keyin — oddiyga qaytadi).
  Future<void> almashtir() async {
    value = (value + 1) % darajalar.length;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kalit, value);
  }
}
