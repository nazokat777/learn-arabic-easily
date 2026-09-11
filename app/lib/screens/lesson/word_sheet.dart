import 'package:flutter/material.dart' hide Text;
import '../../widgets/uz_text.dart';
import '../../arabic.dart';
import '../../content.dart';
import '../../lugat.dart';
import '../../services/tts.dart';
import '../../theme.dart';
import '../../widgets/rasm_belgi.dart';

/// Arabcha so'zga bosilganda ochiladigan interaktiv karta:
/// ma'no, taxminiy talaffuz, audio, harflar, grammatik shakllar (kitobdan),
/// va misol jumla (dars matnidan olinadi — kontent o'zgarmaydi).
/// [bosilgan] — matnda bosilgan so'zning ASL shakli, agar u lug'atdagi
/// shakldan farq qilsa (masalan «الكلمات» bosilib, lug'atdan «كلمة»
/// topilgan bo'lsa). Shunda o'quvchi qaysi so'z qaysisiga bog'langanini
/// ko'radi — aks holda kartada butunlay boshqa so'z chiqqandek tuyulardi.
void showWordSheet(
  BuildContext context,
  QiroatVocab v, {
  String? reading,
  String? bosilgan,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _WordSheet(v: v, reading: reading, bosilgan: bosilgan),
  );
}

class _WordSheet extends StatelessWidget {
  final QiroatVocab v;
  final String? reading;
  final String? bosilgan;
  const _WordSheet({required this.v, this.reading, this.bosilgan});

  @override
  Widget build(BuildContext context) {
    final forms = splitForms(v.ar);
    final head = forms.isNotEmpty ? forms.first : v.ar;
    final letters = stripDiacritics(
      head,
    ).split('').where((c) => c.trim().isNotEmpty).toList();
    final example = _findExample();

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Bosh so'z + audio (konkret ot bo'lsa — rasm bilan)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RasmBelgi(uz: v.uz, olcham: 56),
                const SizedBox(width: 10),
                Flexible(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      head,
                      textAlign: TextAlign.center,
                      style: AppTheme.arabic(
                        size: 44,
                        color: AppColors.emerald,
                        w: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _PlayButton(text: head, big: true),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                '≈ ${approxTranslit(head)}',
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (bosilgan != null &&
                Lugat.kalit(bosilgan!) != Lugat.kalit(head)) ...[
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Matndagi shakli:',
                        style: TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                      const SizedBox(width: 6),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          bosilgan!,
                          style: AppTheme.arabic(
                            size: 20,
                            color: AppColors.gold,
                            w: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            // Ma'no
            _card(
              icon: Icons.translate_rounded,
              label: 'Ma\'nosi',
              child: Text(
                v.uz,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            // Grammatika
            _grammarCard(forms),
            // Harflar
            if (letters.isNotEmpty)
              _card(
                icon: Icons.spellcheck_rounded,
                label: 'Harflar',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  textDirection: TextDirection.rtl,
                  children: letters
                      .map(
                        (c) => Container(
                          width: 40,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.softGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c,
                            style: AppTheme.arabic(
                              size: 24,
                              color: AppColors.emeraldDark,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            // Misol jumla (matndan)
            if (example != null)
              _card(
                icon: Icons.menu_book_rounded,
                label: 'Misol (dars matnidan)',
                trailing: _PlayButton(text: example, big: false),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    example,
                    textAlign: TextAlign.right,
                    style: AppTheme.arabic(
                      size: 22,
                      color: AppColors.ink,
                      w: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _grammarCard(List<String> forms) {
    final rows = <Widget>[];
    if (v.pl.trim().isNotEmpty) {
      rows.add(_grammarRow('Ism (ot) · ko\'plik', v.pl));
    }
    if (forms.length >= 3) {
      const labels4 = [
        'Moziy (o\'tgan)',
        'Muzori\' (hozir/kelasi)',
        'Amr (buyruq)',
        'Masdar (harakat nomi)',
      ];
      const labels3 = [
        'Moziy (o\'tgan)',
        'Muzori\' (hozir/kelasi)',
        'Masdar (harakat nomi)',
      ];
      final labels = forms.length == 4
          ? labels4
          : (forms.length == 3 ? labels3 : null);
      for (int i = 0; i < forms.length; i++) {
        rows.add(
          _grammarRow(
            labels != null && i < labels.length ? labels[i] : 'Shakli',
            forms[i],
          ),
        );
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _card(
      icon: Icons.account_tree_rounded,
      label: 'Grammatika',
      child: Column(children: rows),
    );
  }

  Widget _grammarRow(String label, String ar) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              ar,
              textAlign: TextAlign.right,
              style: AppTheme.arabic(size: 20, color: AppColors.emerald),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _PlayButton(text: ar, big: false),
      ],
    ),
  );

  Widget _card({
    required IconData icon,
    required String label,
    required Widget child,
    Widget? trailing,
  }) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.gold),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  /// Dars matnidan so'z uchraydigan jumlani topadi (verbatim — o'zgartirilmaydi).
  String? _findExample() {
    if (reading == null) return null;
    final forms = splitForms(v.ar);
    final head = forms.isNotEmpty ? forms.first : v.ar;
    final needle = stripDiacritics(head);
    if (needle.length < 3) return null;
    for (final s in splitSentences(reading!)) {
      if (stripDiacritics(s).contains(needle)) return s;
    }
    return null;
  }
}

/// Audio o'ynatish tugmasi — bosilganda arabcha matnni o'qiydi.
class _PlayButton extends StatelessWidget {
  final String text;
  final bool big;
  const _PlayButton({required this.text, required this.big});

  @override
  Widget build(BuildContext context) {
    final size = big ? 52.0 : 38.0;
    return ValueListenableBuilder<String?>(
      valueListenable: Tts.instance.speakingId,
      builder: (context, speaking, _) {
        final isMe = speaking == text;
        return Material(
          color: isMe ? AppColors.gold : AppColors.emerald,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Tts.instance.speak(text, id: text),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                isMe ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: big ? 28 : 22,
              ),
            ),
          ),
        );
      },
    );
  }
}
