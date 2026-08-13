// Content sanity check across ALL lessons, run through the app's OWN helpers.
//
// Cheaper and stricter than eyeballing screenshots: it proves every lesson can
// actually be turned into the pieces the guided flow needs (sentences, tappable
// word tokens, verb forms) and flags anything the UI would struggle to lay out.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/arabic.dart';

void main() {
  final raw = File('assets/content/qiroat_lessons.json').readAsStringSync();
  final lessons = (json.decode(raw)['lessons'] as List).cast<Map<String, dynamic>>();

  String id(Map l) => 'b${l['book'] ?? 1}-L${l['num']}';

  test('every lesson yields sentences the Read stage can show', () {
    final problems = <String>[];
    for (final l in lessons) {
      final sentences = splitSentences(l['reading'] as String);
      if (sentences.isEmpty) {
        problems.add('${id(l)}: reading produced NO sentences');
        continue;
      }
      for (final s in sentences) {
        // Guards against a whole paragraph collapsing into one "sentence"
        // because a full stop was dropped while transcribing. The threshold is
        // above the longest run-on the books actually print: classical Arabic
        // prose genuinely runs to ~500 characters between full stops (book 3
        // lessons 30, 36, 42, 47 and 53 were each checked against the page
        // image and are faithful).
        if (s.length > 600) {
          problems.add('${id(l)}: sentence of ${s.length} chars — '
              '"${s.substring(0, 60)}…"');
        }
        if (tokenize(s).where((t) => t.isWord).isEmpty) {
          problems.add('${id(l)}: sentence with no tappable word — "$s"');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('every vocab entry is usable by the word sheet and drills', () {
    final problems = <String>[];
    for (final l in lessons) {
      for (final w in (l['vocab'] as List).cast<Map<String, dynamic>>()) {
        final ar = (w['ar'] as String).trim();
        final uz = (w['uz'] as String).trim();
        if (ar.isEmpty || uz.isEmpty) {
          problems.add('${id(l)}: empty ar/uz');
          continue;
        }
        if (splitForms(ar).isEmpty) {
          problems.add('${id(l)}: splitForms empty for "$ar"');
        }
        if (stripDiacritics(ar).trim().isEmpty) {
          problems.add('${id(l)}: "$ar" is diacritics only');
        }
        if (approxTranslit(splitForms(ar).first).trim().isEmpty) {
          problems.add('${id(l)}: no translit for "$ar"');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('lesson set is complete and free of duplicates', () {
    final byBook = <int, List<int>>{};
    for (final l in lessons) {
      byBook.putIfAbsent(l['book'] as int? ?? 1, () => []).add(l['num'] as int);
    }
    expect(byBook.keys.toList()..sort(), [1, 2, 3]);
    const expected = {1: 52, 2: 60, 3: 57};
    expected.forEach((book, count) {
      final nums = byBook[book]!..sort();
      expect(nums.length, count, reason: 'book $book lesson count');
      expect(nums.toSet().length, count, reason: 'book $book has duplicates');
      expect(nums, List.generate(count, (i) => i + 1),
          reason: 'book $book numbering has a gap');
    });
  });

  test('alphabet data matches standard Arabic', () {
    final letters = (json.decode(
            File('assets/content/letters.json').readAsStringSync())['letters']
        as List).cast<Map<String, dynamic>>();

    // Standart hijoiy tartib — kitoblar ham shu tartibda o'rgatadi.
    const order = 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي';
    expect(letters.length, 28);
    expect(letters.map((l) => l['ar']).join(), order);

    // Faqat shu olti harf o'zidan keyingisiga ulanmaydi.
    const nonConnecting = {'ا', 'د', 'ذ', 'ر', 'ز', 'و'};
    for (final l in letters) {
      expect(l['connectsLeft'], !nonConnecting.contains(l['ar']),
          reason: 'ulanish belgisi: ${l['ar']}');
      expect((l['name_ar'] as String).trim(), isNotEmpty);
    }
  });

  test('letter quiz can always build four distinct options', () {
    final letters = (json.decode(
            File('assets/content/letters.json').readAsStringSync())['letters']
        as List).cast<Map<String, dynamic>>();
    // ح va ه ning o'zbekcha nomi bir xil («Haa»), shuning uchun variantlar
    // NOM bo'yicha ajratiladi. Har bir harf uchun kamida 3 ta boshqa nom
    // topilishi shart, aks holda test savoli to'liq chiqmaydi.
    final names = letters.map((l) => l['name_uz'] as String).toList();
    for (final n in names) {
      expect(names.where((x) => x != n).toSet().length, greaterThanOrEqualTo(3),
          reason: 'variant yetarli emas: $n');
    }
  });
}
