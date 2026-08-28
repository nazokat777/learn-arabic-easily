/// Arab matni bilan ishlash yordamchilari — harakatlarni ajratish,
/// jumlalarga va so'zlarga bo'lish, taxminiy talaffuz (lotin).
/// Hech qanday kontentni O'ZGARTIRMAYDI — faqat ko'rsatish/qidirish uchun.
library;

/// Harakat, shadda, sukun, tanvin, tatvil va boshqa belgilar.
final RegExp _diacritics = RegExp(
  '[ً-ْٓ-ٕٖ-ٰٟـۖ-ۭ࣓-ࣿ]',
);

/// So'z belgilari: arab harflari + harakatlar + ZWJ (ulash belgisi).
final RegExp _wordChar = RegExp(
  '[ء-يً-ْٰـ‍]',
);

/// Harakatlarni olib tashlaydi (qidirish/solishtirish uchun).
String stripDiacritics(String s) =>
    s.replaceAll(_diacritics, '').replaceAll('‍', '').trim();

/// Matnni o'qish jumlalariga bo'ladi.
/// She'rlar (\n bilan) — har satr alohida; nasr — nuqta/so'roq/undov bo'yicha.
/// Ajratuvchi belgi jumlaga qo'shib qoldiriladi (matn o'zgarmaydi).
List<String> splitSentences(String reading) {
  final out = <String>[];
  for (final line in reading.split('\n')) {
    final t = line.trim();
    if (t.isEmpty) continue;
    // She'r satri (nuqtasiz) — butunligicha bir jumla.
    final buf = StringBuffer();
    for (int i = 0; i < t.length; i++) {
      final ch = t[i];
      buf.write(ch);
      if (ch == '.' || ch == '؟' || ch == '!' || ch == '؛' || ch == '?') {
        // ketma-ket ajratuvchilarni birga oling
        while (i + 1 < t.length &&
            (t[i + 1] == '.' || t[i + 1] == '؟' || t[i + 1] == '!' || t[i + 1] == '؛')) {
          i++;
          buf.write(t[i]);
        }
        final s = buf.toString().trim();
        if (s.isNotEmpty) out.add(s);
        buf.clear();
      }
    }
    final rest = buf.toString().trim();
    if (rest.isNotEmpty) out.add(rest);
  }
  return out;
}

/// Jumla tokeni: so'z (bosiladigan) yoki oraliq (bo'sh joy/tinish belgisi).
class ArToken {
  final String text;
  final bool isWord;
  const ArToken(this.text, this.isWord);
}

/// Jumlani so'z va oraliq tokenlariga ajratadi (bosiladigan so'zlar uchun).
List<ArToken> tokenize(String sentence) {
  final tokens = <ArToken>[];
  final buf = StringBuffer();
  bool? curWord;
  void flush() {
    if (buf.isEmpty) return;
    tokens.add(ArToken(buf.toString(), curWord ?? false));
    buf.clear();
  }

  for (final r in sentence.runes) {
    final ch = String.fromCharCode(r);
    final isW = _wordChar.hasMatch(ch);
    if (curWord == null || isW == curWord) {
      buf.write(ch);
      curWord = isW;
    } else {
      flush();
      buf.write(ch);
      curWord = isW;
    }
  }
  flush();
  return tokens;
}

/// Ko'p so'zli lug'at (masalan fe'l shakllari «غَلِطَ، يَغْلَطُ...») —
/// vergul bilan ajratilgan qismlarga bo'ladi.
List<String> splitForms(String ar) => ar
    .split(RegExp('[،,]'))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

/// Lug'at so'zi ishlatilgan jumlani matndan topadi.
///
/// Nega kerak: TTS yolg'iz turgan arabcha so'zni «vaqf» shaklida o'qiydi -
/// oxirgi qisqa unlini tushiradi («tafarrasa» → «tafarras»). Jumla ichida
/// esa so'z to'liq o'qiladi. Shuning uchun lug'at qatoriga «jumlada
/// tinglash» tugmasi qo'yiladi va u shu jumlani ijro etadi.
///
/// Solishtirish harakatsiz shaklda boradi: matnda so'z boshqa harakat bilan
/// kelishi mumkin. Prefikslar (وَ، بِ، الْ...) tufayli aniq tenglik
/// bo'lmasligi ham mumkin, shuning uchun tenglik topilmasa so'z tokenning
/// ichida kelishiga ham roziday bo'lamiz. Bir nechta jumla mos kelsa eng
/// qisqasi olinadi - misol qisqa bo'lgani tushunarli.
String? findSentenceFor(String vocabAr, String reading) {
  final forms = splitForms(vocabAr).map(stripDiacritics).where((e) => e.isNotEmpty).toList();
  if (forms.isEmpty || reading.trim().isEmpty) return null;

  String? exact, loose;
  for (final sentence in splitSentences(reading)) {
    final words = tokenize(sentence)
        .where((t) => t.isWord)
        .map((t) => stripDiacritics(t.text))
        .where((w) => w.isNotEmpty)
        .toList();
    for (final f in forms) {
      if (words.contains(f)) {
        if (exact == null || sentence.length < exact.length) exact = sentence;
      } else if (words.any((w) => w.length > f.length && w.contains(f))) {
        if (loose == null || sentence.length < loose.length) loose = sentence;
      }
    }
  }
  return exact ?? loose;
}

// --- Taxminiy talaffuz (lotin) — o'qishga yordam, aniq transkripsiya emas. ---

const Map<String, String> _cons = {
  'ا': 'ā', 'أ': 'a', 'إ': 'i', 'آ': 'ā', 'ٱ': 'a',
  'ب': 'b', 'ت': 't', 'ث': 's', 'ج': 'j', 'ح': 'h', 'خ': 'x',
  'د': 'd', 'ذ': 'z', 'ر': 'r', 'ز': 'z', 'س': 's', 'ش': 'sh',
  'ص': 's', 'ض': 'd', 'ط': 't', 'ظ': 'z', 'ع': 'ʼ', 'غ': "g'",
  'ف': 'f', 'ق': 'q', 'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n',
  'ه': 'h', 'و': 'w', 'ي': 'y', 'ء': 'ʼ', 'ؤ': 'ʼ', 'ئ': 'ʼ',
  'ى': 'ā', 'ة': 'h',
};

/// So'zning taxminiy lotin o'qilishi (talaffuzga yordam).
String approxTranslit(String word) {
  final b = StringBuffer();
  final chars = word.runes.map(String.fromCharCode).toList();
  for (int i = 0; i < chars.length; i++) {
    final ch = chars[i];
    switch (ch) {
      case 'َ': // fatha
        b.write('a');
        break;
      case 'ِ': // kasra
        b.write('i');
        break;
      case 'ُ': // damma
        b.write('u');
        break;
      case 'ً': // fathatan
        b.write('an');
        break;
      case 'ٍ': // kasratan
        b.write('in');
        break;
      case 'ٌ': // dammatan
        b.write('un');
        break;
      case 'ّ': // shadda -> oldingi undoshni qo'shlaymiz
        final prev = b.toString();
        if (prev.isNotEmpty) b.write(prev[prev.length - 1]);
        break;
      case 'ْ': // sukun
        break;
      case 'ٰ': // xanjarli alif
        b.write('ā');
        break;
      case 'ـ': // tatvil
      case '‍': // ZWJ
        break;
      default:
        b.write(_cons[ch] ?? ch);
    }
  }
  return b.toString();
}
