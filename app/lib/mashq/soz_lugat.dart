import '../arabic.dart';
import '../main.dart';

/// Ilovadagi barcha darslardan yig'ilgan «arabcha so'z → o'zbekcha ma'no»
/// lug'ati. Gap tuzish va tushuntirish oynalarida har bir so'z ustiga
/// bosilganda tarjima shu yerdan olinadi. Harakatsiz shaklda solishtiriladi.
class SozLugat {
  SozLugat._();

  static Map<String, String>? _xarita;

  static String _kalit(String s) => stripDiacritics(
    s.replaceAll(RegExp('[^ء-ي\u064B-\u0652\u0670]'), ''),
  );

  static void _qosh(Map<String, String> m, String ar, String uz) {
    final u = uz.trim();
    if (u.isEmpty || RegExp('[؀-ۿ]').hasMatch(u)) return;
    for (final f in splitForms(ar)) {
      final bola = f.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
      if (bola.length != 1) continue;
      final k = _kalit(bola.first);
      if (k.isEmpty) continue;
      m.putIfAbsent(k, () => u);
    }
  }

  static Map<String, String> get _lugat {
    final m = _xarita;
    if (m != null) return m;
    final yangi = <String, String>{};
    try {
      repo.qiroatLessons;
    } catch (_) {
      return yangi; // kontent hali yuklanmagan — keshlanmaydi
    }
    for (final l in repo.qiroatLessons) {
      for (final v in l.vocab) {
        _qosh(yangi, v.ar, v.uz);
      }
    }
    for (final l in repo.nahvLessons) {
      for (final b in l.blocks) {
        for (final p in b.items) {
          _qosh(yangi, p.ar, p.uz);
        }
      }
    }
    return _xarita = yangi;
  }


  /// So'zning o'zbekcha ma'nosi; topilmasa `null`.
  /// Old qo'shimchalar (و، ف، ب، ل، ك، س) va «ال» olinib ham qidiriladi.
  static String? tarjima(String soz) {
    final k = _kalit(soz);
    if (k.isEmpty) return null;
    final m = _lugat;
    final d = m[k];
    if (d != null) return d;
    final nomzod = <String>[];
    if (k.length > 3 && k.startsWith('ال')) nomzod.add(k.substring(2));
    if (k.length > 2 && 'وفبلكس'.contains(k[0])) {
      final r = k.substring(1);
      nomzod.add(r);
      if (r.length > 3 && r.startsWith('ال')) nomzod.add(r.substring(2));
    }
    for (final n in nomzod) {
      final t = m[n];
      if (t != null) return t;
    }
    return null;
  }

}
