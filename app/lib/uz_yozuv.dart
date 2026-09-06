import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O'zbek yozuvi — lotin yoki kirill.
///
/// Nega kerak: O'zbekistonda ikkala yozuv ham kundalik ishlatiladi. Katta
/// yoshli o'quvchilar kirilda ravon o'qiydi, lotinda esa qiynaladi —
/// arab tilini o'rganish allaqachon og'ir, ustiga notanish alifboda
/// o'qish qo'shimcha to'siq bo'lmasligi kerak.
///
/// Yondashuv: kontent (darslar, lug'at, izohlar) BITTA nusxada — lotinda —
/// saqlanadi va ekranga chiqishdan oldin kirillga o'giriladi. Ikkinchi
/// nusxa saqlanmaydi: 265 dars ikki xil yozuvda yotsa, ular albatta bir-
/// biridan ajralib ketardi va xato tuzatilganda faqat bittasida tuzalardi.
enum Yozuv { lotin, kirill }

/// Tanlangan yozuv. `MaterialApp` shu qiymatni tinglaydi — almashtirilsa
/// butun ilova qayta chiziladi.
class UzYozuv extends ValueNotifier<Yozuv> {
  UzYozuv._() : super(Yozuv.lotin);
  static final UzYozuv instance = UzYozuv._();

  static const _kalit = 'yozuv';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    value = p.getString(_kalit) == 'kirill' ? Yozuv.kirill : Yozuv.lotin;
  }

  Future<void> almashtir() async {
    value = value == Yozuv.lotin ? Yozuv.kirill : Yozuv.lotin;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kalit, value == Yozuv.kirill ? 'kirill' : 'lotin');
  }

  bool get kirill => value == Yozuv.kirill;
}

/// Ekranga chiqadigan matn. Lotin tanlangan bo'lsa — o'zgarishsiz.
String uz(String matn) => UzYozuv.instance.kirill ? kirillga(matn) : matn;

/// Lotin harflari bo'lmagan matn (arabcha, raqam) o'zgarishsiz o'tadi,
/// shuning uchun aralash satrni ham xavfsiz uzatish mumkin:
/// «Jumla tuzilishi — «الدروس النحوية» kitobidan» → faqat lotin qismi o'giriladi.
final Map<String, String> _kesh = {};

/// Lotin yozuvidagi o'zbekcha matnni kirillga o'giradi.
String kirillga(String matn) {
  final tayyor = _kesh[matn];
  if (tayyor != null) return tayyor;
  final natija = _ogir(matn);
  // Kesh cheksiz o'smasin: darslar almashganda eski satrlar kerak emas.
  if (_kesh.length > 3000) _kesh.clear();
  _kesh[matn] = natija;
  return natija;
}

/// Lotin yozuvida «o'» va «g'» uchun turli belgilar ishlatiladi (oddiy
/// apostrof, tipografik qo'shtirnoq, modifikator harflar) — hammasi bir xil
/// qabul qilinadi, aks holda bitta satr o'girilib, boshqasi o'girilmasdan
/// qolardi.
const String _apostroflar = "'‘’ʻʼ´`";

/// O'girilmaydigan qisqartmalar — ular kirillda ham lotincha yoziladi.
const Set<String> _saqlanadi = {
  'APK',
  'PDF',
  'HTML',
  'JSON',
  'MP3',
  'TTS',
  'GSAP',
  'ZWJ',
  'KB',
  'MB',
  'GB',
  'ID',
  'OK',
  'TV',
  'USB',
  'QR',
};

const Map<String, String> _bir = {
  'a': 'а',
  'b': 'б',
  'd': 'д',
  'f': 'ф',
  'g': 'г',
  'h': 'ҳ',
  'i': 'и',
  'j': 'ж',
  'k': 'к',
  'l': 'л',
  'm': 'м',
  'n': 'н',
  'o': 'о',
  'p': 'п',
  'q': 'қ',
  'r': 'р',
  's': 'с',
  't': 'т',
  'u': 'у',
  'v': 'в',
  'x': 'х',
  'y': 'й',
  'z': 'з',
};

bool _lotinHarf(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 65 && u <= 90) || (u >= 97 && u <= 122);
}

String _bosh(String s) => s[0].toUpperCase() + s.substring(1);

String _ogir(String s) {
  final out = StringBuffer();
  var i = 0;

  bool apostrof(int k) => i + k < s.length && _apostroflar.contains(s[i + k]);
  String? keyingi(int k) => i + k < s.length ? s[i + k].toLowerCase() : null;

  while (i < s.length) {
    final c = s[i];

    // Qisqartma so'zning boshida turibdimi — o'girmasdan o'tkazamiz.
    if (_lotinHarf(c) && (i == 0 || !_lotinHarf(s[i - 1]))) {
      var j = i;
      while (j < s.length && _lotinHarf(s[j])) {
        j++;
      }
      final soz = s.substring(i, j);
      if (_saqlanadi.contains(soz)) {
        out.write(soz);
        i = j;
        continue;
      }
    }

    final past = c.toLowerCase();
    final katta = c != past && _lotinHarf(c);
    String? almash;
    var uzunlik = 1;

    if (past == 'o' && apostrof(1)) {
      almash = 'ў';
      uzunlik = 2;
    } else if (past == 'g' && apostrof(1)) {
      almash = 'ғ';
      uzunlik = 2;
    } else if (past == 'y' && keyingi(1) == 'o' && apostrof(2)) {
      // «yo'l» — bu «yo» qo'shbirikmasi emas, «y» + «o'». Shu tekshiruvsiz
      // «йўл» o'rniga «ёъл» chiqardi.
      almash = 'й';
    } else if (past == 's' && keyingi(1) == 'h') {
      almash = 'ш';
      uzunlik = 2;
    } else if (past == 'c' && keyingi(1) == 'h') {
      almash = 'ч';
      uzunlik = 2;
    } else if (past == 'y' && keyingi(1) == 'a') {
      almash = 'я';
      uzunlik = 2;
    } else if (past == 'y' && keyingi(1) == 'o') {
      almash = 'ё';
      uzunlik = 2;
    } else if (past == 'y' && keyingi(1) == 'u') {
      almash = 'ю';
      uzunlik = 2;
    } else if (past == 'y' && keyingi(1) == 'e') {
      almash = 'е';
      uzunlik = 2;
    } else if (past == 'e') {
      // So'z boshida «э», ichida «е»: «eshik» → эшик, «kel» → кел.
      almash = (i == 0 || !_lotinHarf(s[i - 1])) ? 'э' : 'е';
    } else if (_apostroflar.contains(c)) {
      // Tutuq belgisi — faqat harflar orasida: «ma'no» → маъно.
      // So'z chetidagi qo'shtirnoq tinish belgisi bo'lib qoladi.
      if (i > 0 &&
          _lotinHarf(s[i - 1]) &&
          i + 1 < s.length &&
          _lotinHarf(s[i + 1])) {
        almash = 'ъ';
      }
    } else {
      almash = _bir[past];
    }

    if (almash == null) {
      out.write(c);
      i += 1;
      continue;
    }
    out.write(katta ? _bosh(almash) : almash);
    i += uzunlik;
  }
  return out.toString();
}
