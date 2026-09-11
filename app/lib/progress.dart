import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Foydalanuvchi taraqqiyoti: XP, olov (streak), tugatilgan darslar,
/// va har bir so'z uchun yodlash darajasi.
/// Mahalliy saqlanadi (shared_preferences) — offline ishlaydi.
class Progress extends ChangeNotifier {
  /// So'z «yodlangan» hisoblanishi uchun nechta marta to'g'ri javob kerak.
  static const int masteryGoal = 5;

  int xp = 0;
  int streak = 0;
  String? _lastActiveDay; // 'YYYY-MM-DD'
  final Set<String> _completed = {};
  // Har bir so'z uchun to'g'ri javoblar soni (0..masteryGoal). Kalit: darsId::arabcha
  final Map<String, int> _mastery = {};

  /// Ko'p usulli yodlash: so'z HAR usulda kamida bir marta to'g'ri o'tilishi kerak.
  /// Har usul — bitta bit. So'z «to'liq yodlangan» = barcha usullar bitlari yoqilgan.
  static const int masterModeCount =
      6; // tanish, teskari, eshit, top, harflar, gap
  static const int allModesMask = (1 << masterModeCount) - 1; // 63
  final Map<String, int> _modeMask =
      {}; // darsId::arabcha -> bajarilgan usullar bitmaskasi

  /// «O'zlashtirilgan» darslar — testdan BITTA HAM xatosiz o'tilganlari.
  ///
  /// Nega `_completed` dan alohida: `_completed` «darsni ko'rib chiqdi»
  /// degani, u eski qoida bo'yicha (60% yetarli edi) yig'ilgan. Yangi qoida
  /// qattiqroq, ammo eski belgilarni o'chirib tashlash o'quvchining
  /// mehnatini yo'qqa chiqaradi — shuning uchun ikkalasi yonma-yon turadi.
  final Set<String> _mastered = {};

  /// Har bir dars uchun eng yaxshi natija — birinchi urinishda to'g'ri
  /// javoblar foizi (0..100). O'quvchi «qancha qoldi» ni ko'rib tursin.
  final Map<String, int> _best = {};

  /// Har bir mashq elementi bo'yicha XATO soni va URINISHLAR soni.
  ///
  /// Nega kerak: «daraja» (`_mastery`) faqat hozirgi holatni ko'rsatadi —
  /// bugun to'g'ri javob bergan so'z 5 ga chiqadi va o'tmishdagi qiynalish
  /// izsiz yo'qoladi. Holbuki qaysi so'z QIYIN kelayotganini bilish uchun
  /// aynan xatolar tarixi kerak: shu ikki raqam «zaif ro'yxat» ni yasaydi
  /// va takrorlash aynan o'sha elementlarga qaratiladi.
  final Map<String, int> _xato = {};
  final Map<String, int> _urinish = {};

  /// Element bo'yicha KETMA-KET to'g'ri javoblar soni (xatoda nolga tushadi).
  ///
  /// Nega kerak: «qiyin» so'z ro'yxatdan chiqishi uchun bir marta to'g'ri
  /// javob yetmaydi — tasodif bo'lishi mumkin. Uch marta ketma-ket to'g'ri
  /// bo'lsagina so'z chindan o'rnashgan deb hisoblanadi.
  final Map<String, int> _ketma = {};

  /// Shuncha xatodan keyin element «qiyin» hisoblanadi.
  static const int qiyinChegara = 3;

  /// Shuncha ketma-ket to'g'ri javobdan keyin «qiyin» belgisi olinadi.
  static const int qiyinChiqish = 3;

  /// Kunlik maqsad — bir kunda shuncha savolga javob berish.
  ///
  /// Nega 20: bitta mashq sessiyasining 2-3 raundi. Katta maqsad
  /// cho'chitadi, kichigi mukofot bo'lmaydi. Maqsad kunda bir marta
  /// bajariladi va bir marta mukofotlanadi — «yana bitta» hissi
  /// ertaga ham qaytib kelsin.
  static const int kunlikMaqsad = 20;
  static const int kunlikMukofotBalli = 10;
  int _kunSoni = 0;
  String? _kunSana;
  bool _kunMukofotOlindi = false;

  SharedPreferences? _prefs;

  int get level => (xp ~/ 100) + 1;
  int get xpInLevel => xp % 100;
  double get levelProgress => xpInLevel / 100.0;

  static const List<String> levelNames = [
    // Xalqaro «metall» zinapoyasi — har kim tushunadi, oltin/zumrad
    // ranglarga mos. Har 100 ball = keyingi pog'ona.
    'Bronza', 'Bronza +', 'Kumush', 'Kumush +', 'Oltin',
    'Oltin +', 'Platina', 'Platina +', 'Olmos', 'Legenda',
  ];
  String get levelName =>
      levelNames[(level - 1).clamp(0, levelNames.length - 1)];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    xp = _prefs!.getInt('xp') ?? 0;
    streak = _prefs!.getInt('streak') ?? 0;
    _lastActiveDay = _prefs!.getString('lastDay');
    _completed.addAll(_prefs!.getStringList('completed') ?? []);
    final ms = _prefs!.getString('mastery');
    if (ms != null) {
      (json.decode(ms) as Map).forEach(
        (k, v) => _mastery[k as String] = (v as num).toInt(),
      );
    }
    final mm = _prefs!.getString('modeMask');
    if (mm != null) {
      (json.decode(mm) as Map).forEach(
        (k, v) => _modeMask[k as String] = (v as num).toInt(),
      );
    }
    _mastered.addAll(_prefs!.getStringList('mastered') ?? []);
    final bs = _prefs!.getString('best');
    if (bs != null) {
      (json.decode(bs) as Map).forEach(
        (k, v) => _best[k as String] = (v as num).toInt(),
      );
    }
    final xs = _prefs!.getString('xato');
    if (xs != null) {
      (json.decode(xs) as Map).forEach(
        (k, v) => _xato[k as String] = (v as num).toInt(),
      );
    }
    final us = _prefs!.getString('urinish');
    if (us != null) {
      (json.decode(us) as Map).forEach(
        (k, v) => _urinish[k as String] = (v as num).toInt(),
      );
    }
    _kunSana = _prefs!.getString('kunSana');
    _kunSoni = _prefs!.getInt('kunSoni') ?? 0;
    _kunMukofotOlindi = _prefs!.getBool('kunMukofot') ?? false;
    final ks = _prefs!.getString('ketma');
    if (ks != null) {
      (json.decode(ks) as Map).forEach(
        (k, v) => _ketma[k as String] = (v as num).toInt(),
      );
    }
    _refreshStreak();
    notifyListeners();
  }

  /// So'zning yodlash darajasi (0..masteryGoal).
  int wordMastery(String key) => _mastery[key] ?? 0;

  /// So'z to'liq yodlanganmi (masteryGoal marta to'g'ri).
  bool isWordLearned(String key) => (_mastery[key] ?? 0) >= masteryGoal;

  /// To'g'ri javobda +1, xatoda -1 (0..masteryGoal orasida). Yangi darajani qaytaradi.
  Future<int> bumpWord(String key, bool correct) async {
    _kunlikQosh();
    final cur = _mastery[key] ?? 0;
    final next = (correct ? cur + 1 : cur - 1).clamp(0, masteryGoal);
    _mastery[key] = next;
    _urinish[key] = (_urinish[key] ?? 0) + 1;
    if (correct) {
      _ketma[key] = (_ketma[key] ?? 0) + 1;
    } else {
      _xato[key] = (_xato[key] ?? 0) + 1;
      _ketma[key] = 0;
    }
    await _save();
    notifyListeners();
    return next;
  }

  /// Element bo'yicha xatolar soni (butun tarix bo'yicha).
  int xatoSoni(String key) => _xato[key] ?? 0;

  /// Element necha marta so'ralgan.
  int urinishSoni(String key) => _urinish[key] ?? 0;

  /// Element hech qachon so'ralmaganmi.
  bool yangiElement(String key) => !_urinish.containsKey(key);

  /// Element bo'yicha hozirgi ketma-ket to'g'ri javoblar soni.
  int ketmaKetTogri(String key) => _ketma[key] ?? 0;

  /// Element «qiyin» ro'yxatidami: kamida [qiyinChegara] marta xato
  /// qilingan va hali [qiyinChiqish] marta ketma-ket to'g'ri berilmagan.
  ///
  /// Bu ro'yxat oddiy «zaiflik» og'irligidan farq qiladi: zaiflik
  /// takrorda so'zni sal ko'proq chiqaradi, «qiyin» esa so'zni ALOHIDA
  /// o'rgatish bosqichiga olib boradi — avval ko'rsatib, keyin so'raydi.
  bool qiyinMi(String key) =>
      xatoSoni(key) >= qiyinChegara && ketmaKetTogri(key) < qiyinChiqish;

  /// Hozir «qiyin» ro'yxatida turgan kalitlar. Faqat xato qilinganlar
  /// ko'rib chiqiladi — bosh ekranda har qayta chizishda butun kontentni
  /// aylanib chiqmaslik uchun.
  Iterable<String> get qiyinKalitlar => _xato.keys.where(qiyinMi);

  /// Elementning «zaiflik» og'irligi — takrorlashda qaysi element ko'proq
  /// chiqishini shu belgilaydi. Katta son = ko'proq mashq kerak.
  ///
  /// Hisob: xatolar eng og'ir turadi, past daraja qo'shimcha og'irlik
  /// beradi, hech ko'rilmagan element esa o'rtacha og'irlik oladi — u
  /// hali «zaif» emas, lekin baribir so'ralishi kerak.
  double zaiflik(String key) {
    if (yangiElement(key)) return 2.0;
    final xato = _xato[key] ?? 0;
    final daraja = _mastery[key] ?? 0;
    return 1.0 + xato * 2.0 + (masteryGoal - daraja) * 0.5;
  }

  // --- Ko'p usulli mastery (master drill) ---

  /// So'zning bajarilgan usullari bitmaskasi.
  int wordModeMask(String key) => _modeMask[key] ?? 0;

  /// So'z shu usulda o'tilganmi.
  bool isModeDone(String key, int mode) =>
      (wordModeMask(key) & (1 << mode)) != 0;

  /// Bajarilgan usullar soni (0..masterModeCount).
  int masterCount(String key) {
    final m = wordModeMask(key);
    int c = 0;
    for (var i = 0; i < masterModeCount; i++) {
      if (m & (1 << i) != 0) c++;
    }
    return c;
  }

  /// So'z barcha usullarda yodlanganmi.
  bool isWordMastered(String key) =>
      (wordModeMask(key) & allModesMask) == allModesMask;

  /// Usul natijasini belgilash: to'g'ri bo'lsa bitni yoqadi; xato bo'lsa o'sha bitni o'chiradi.
  Future<void> markMode(String key, int mode, bool correct) async {
    _kunlikQosh();
    final cur = _modeMask[key] ?? 0;
    _modeMask[key] = correct ? (cur | (1 << mode)) : (cur & ~(1 << mode));
    await _save();
    notifyListeners();
  }

  // --- Kunlik maqsad ---

  /// Bugun javob berilgan savollar soni (kun almashsa nolga tushadi).
  int get bugungiSavollar => _kunSana == _today() ? _kunSoni : 0;

  bool get kunlikMaqsadBajarildi => bugungiSavollar >= kunlikMaqsad;

  /// Bugungi mukofot allaqachon olinganmi.
  bool get kunlikMukofotOlindi =>
      _kunSana == _today() && _kunMukofotOlindi;

  void _kunlikQosh() {
    final bugun = _today();
    if (_kunSana != bugun) {
      _kunSana = bugun;
      _kunSoni = 0;
      _kunMukofotOlindi = false;
    }
    _kunSoni++;
  }

  /// Kunlik mukofotni beradi — kunda faqat bir marta. Berilgan bo'lsa
  /// `true`; maqsad bajarilmagan yoki allaqachon olingan bo'lsa `false`.
  Future<bool> kunlikMukofotniOl() async {
    if (!kunlikMaqsadBajarildi || kunlikMukofotOlindi) return false;
    _kunMukofotOlindi = true;
    _seriyaniOshir();
    await addXp(kunlikMukofotBalli);
    return true;
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _refreshStreak() {
    final today = _today();
    if (_lastActiveDay == null) return;
    if (_lastActiveDay == today) return;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final y =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    if (_lastActiveDay != y) {
      streak = 0; // seriya uzildi
    }
  }

  Future<void> addXp(int amount) async {
    xp += amount;
    await _save();
    notifyListeners();
  }

  /// Seriya (olov) — KUNLIK MAQSAD bajarilgan kunlar ketma-ketligi.
  ///
  /// Oldin har qanday ball seriyani oshirardi: bitta savolga javob
  /// berib chiqib ketgan kun ham «o'qilgan kun» hisoblanardi va olov
  /// belgisi ma'nosini yo'qotgan edi. Endi olov halol: kun maqsadga
  /// yetilgandagina yonadi, bir kun o'tkazib yuborilsa o'chadi.
  void _seriyaniOshir() {
    final today = _today();
    if (_lastActiveDay == today) return;
    _lastActiveDay = today;
    streak += 1;
  }

  /// Bugun seriya uchun hisoblangan kunmi (maqsad bajarilgan).
  bool get bugunSeriyada => _lastActiveDay == _today();

  bool isCompleted(String lessonId) => _completed.contains(lessonId);

  Future<void> markCompleted(String lessonId) async {
    _completed.add(lessonId);
    await _save();
    notifyListeners();
  }

  // --- Darsni o'zlashtirish (test natijasi bo'yicha) ---

  /// Dars o'zlashtirilganmi — ya'ni test bir marta xatosiz topshirilganmi.
  bool isMastered(String lessonId) => _mastered.contains(lessonId);

  /// Shu darsdagi eng yaxshi natija, foizda (hech urinilmagan bo'lsa 0).
  int bestPercent(String lessonId) => _best[lessonId] ?? 0;

  /// Testda hech urinib ko'rilmaganmi.
  bool isUntried(String lessonId) => !_best.containsKey(lessonId);

  /// Test urinishini yozib qo'yadi.
  ///
  /// [firstTry] — BIRINCHI urinishda to'g'ri javob berilgan savollar soni.
  /// Xatodan keyin qaytarilgan savol to'g'ri yechilsa ham bu songa kirmaydi:
  /// aks holda «xatosiz o'tish» sharti ma'nosini yo'qotardi.
  ///
  /// Dars faqat [firstTry] == [total] bo'lgandagina o'zlashtirilgan
  /// hisoblanadi. Natija oldingisidan yomon bo'lsa, eng yaxshisi saqlanadi.
  /// Qaytaradi: shu urinishda o'zlashtirildimi.
  Future<bool> recordAttempt(String lessonId, int firstTry, int total) async {
    if (total <= 0) return false;
    final pct = (firstTry * 100 / total).round();
    if (pct > (_best[lessonId] ?? -1)) _best[lessonId] = pct;
    final ok = firstTry >= total;
    if (ok) {
      _mastered.add(lessonId);
      _completed.add(lessonId); // o'zlashtirgan bo'lsa, ko'rib chiqqani aniq
    }
    await _save();
    notifyListeners();
    return ok;
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt('xp', xp);
    await p.setInt('streak', streak);
    if (_lastActiveDay != null) await p.setString('lastDay', _lastActiveDay!);
    await p.setStringList('completed', _completed.toList());
    await p.setString('mastery', json.encode(_mastery));
    await p.setString('modeMask', json.encode(_modeMask));
    await p.setStringList('mastered', _mastered.toList());
    await p.setString('best', json.encode(_best));
    await p.setString('xato', json.encode(_xato));
    await p.setString('urinish', json.encode(_urinish));
    await p.setString('ketma', json.encode(_ketma));
    if (_kunSana != null) await p.setString('kunSana', _kunSana!);
    await p.setInt('kunSoni', _kunSoni);
    await p.setBool('kunMukofot', _kunMukofotOlindi);
  }
}
