import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

/// Ilova mavzusi — yorug' yoki qorong'u. Tanlov saqlanadi.
///
/// Qiymat o'zgarganda `ArabApp` palitrani ([AppColors.rejim]) almashtirib
/// butun daraxtni yangi kalit bilan qayta quradi — har vidjet ranglarni
/// qaytadan o'qiydi.
class Mavzu extends ValueNotifier<bool> {
  Mavzu._() : super(false);
  static final Mavzu instance = Mavzu._();

  static const _kalit = 'qorongu';

  bool get qorongu => value;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    value = p.getBool(_kalit) ?? false;
    AppColors.rejim(value);
  }

  Future<void> almashtir() async {
    value = !value;
    AppColors.rejim(value);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kalit, value);
  }
}
