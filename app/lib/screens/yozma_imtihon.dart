import 'dart:math';

import 'package:flutter/material.dart' hide Text;

import '../arabic.dart';
import '../main.dart';
import '../mashq/mukofot.dart' show Portlash;
import '../mashq/tovush.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/entrance.dart';
import '../widgets/motion.dart';
import '../widgets/speak_button.dart';
import '../widgets/uz_text.dart';

/// Yozma imtihon topshirig'i: o'zbekchasi beriladi, arabchasi (harakatsiz
/// ham qabul qilinadi) o'quvchi tomonidan YOZILADI.
class YozmaTopshiriq {
  final String uz;
  final String ar;

  /// Xotira kaliti (progress.bumpWord) — bo'sh bo'lsa yozilmaydi.
  final String kalit;
  const YozmaTopshiriq({required this.uz, required this.ar, this.kalit = ''});
}

/// YOZMA IMTIHON — variantsiz, ko'rsatmasiz.
///
/// O'quvchi o'zbekchasini ko'rib, arabchasini O'ZI teradi. Hech qanday
/// variant, harf ishorasi yoki javob ko'rsatilmaydi — faqat ovoz: bilmasa
/// karnayni bosib eshitadi va eshitganini yozadi (yoki harflab eshitadi).
/// Nega: variantlardan tanlash TANISHni o'lchaydi, «qalamdon»ni yozib
/// berish esa ESLASHni — haqiqiy bilim shu. Javobni ko'rsatib qo'yish
/// «ko'rib ko'chirish»ga aylanadi, shuning uchun ko'rsatilmaydi.
///
/// Klaviatura — to'liq arab alifbosi (28 harf + ة ء ى va bo'sh joy): bu
/// variant emas, yozuv quroli; qurilma klaviaturasi bo'lsa u ham ishlaydi.
class YozmaImtihonEkrani extends StatefulWidget {
  final List<YozmaTopshiriq> topshiriqlar;
  final String sarlavha;

  /// Jumla rejimi: so'zma-so'z solishtiriladi (tinish belgilari tashlanadi).
  final bool jumla;
  const YozmaImtihonEkrani({
    super.key,
    required this.topshiriqlar,
    this.sarlavha = 'Yozma imtihon',
    this.jumla = false,
  });

  @override
  State<YozmaImtihonEkrani> createState() => _YozmaImtihonEkraniState();
}

class _YozmaImtihonEkraniState extends State<YozmaImtihonEkrani> {
  final _rnd = Random();
  late final List<YozmaTopshiriq> _navbat = List.of(widget.topshiriqlar)
    ..shuffle(_rnd);
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  int _i = 0;
  int _urinish = 0; // shu topshiriqdagi xato urinishlar
  bool? _natija; // null — tekshirilmagan; true — to'g'ri
  int _togri = 0; // birinchi urinishda to'g'ri
  int _silkin = 0;
  int _portlash = 0;
  bool _tugadi = false;

  /// «Bilmadim» bosildi — javob ko'rsatildi (xato hisobida); so'z navbat
  /// oxiriga BIR marta qaytadi — ko'rgach, keyinroq o'zi yozib ko'radi.
  bool _korsatildi = false;
  final List<YozmaTopshiriq> _bilmaganlar = [];
  final Set<YozmaTopshiriq> _qaytarilgan = {};

  YozmaTopshiriq get _t => _navbat[_i];

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    Tts.instance.stop();
    super.dispose();
  }

  /// Solishtirish uchun normallashtirish: harakatlar tashlanadi, hamza/alif
  /// shakllari bir xil, ى = ي, tatvil yo'q, tinish belgilari yo'q.
  static String _norm(String s) {
    var t = stripDiacritics(s);
    t = t.replaceAll(RegExp('[أإآٱ]'), 'ا').replaceAll('ى', 'ي');
    t = t.replaceAll(RegExp(r'[^ء-ي\s]'), ' ');
    return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).join(' ');
  }

  void _tekshir() {
    if (_natija == true) return;
    final yozgan = _norm(_ctrl.text);
    if (yozgan.isEmpty) return;
    final ok = yozgan == _norm(_t.ar);
    if (ok) {
      Haptic.ok();
      Tovush.togri(_urinish == 0 ? _togri + 1 : 0);
      setState(() {
        _natija = true;
        _portlash++;
        if (_urinish == 0) _togri++;
      });
      progress.addXp(_urinish == 0 ? 4 : 1);
      if (_t.kalit.isNotEmpty) progress.bumpWord(_t.kalit, _urinish == 0);
      // To'g'ri javob — arabchasi o'qiladi (endi ko'rsatsa ham bo'ladi:
      // o'quvchi o'zi yozdi).
      Tts.instance.speak(_t.ar, id: 'yz-$_i');
    } else {
      Haptic.wrong();
      Tovush.xato();
      setState(() {
        _natija = false;
        _urinish++;
        _silkin++;
      });
      if (_t.kalit.isNotEmpty && _urinish == 1) {
        progress.bumpWord(_t.kalit, false);
      }
    }
  }

  /// «Bilmadim» — javob KO'RSATILADI va o'qiladi (xato hisobida); so'z
  /// navbat oxiriga bir marta qaytadi — ko'rib qo'ygach, keyinroq yodidan
  /// yozib ko'radi. Karnay esa alohida: ko'rsatmasdan faqat eshitish uchun.
  void _bilmadim() {
    if (_natija == true || _korsatildi) return;
    if (_urinish == 0 && _t.kalit.isNotEmpty) {
      progress.bumpWord(_t.kalit, false);
    }
    final t = _t;
    if (!_bilmaganlar.contains(t)) _bilmaganlar.add(t);
    if (!_qaytarilgan.contains(t)) {
      _qaytarilgan.add(t);
      _navbat.add(t);
    }
    setState(() {
      _korsatildi = true;
      _natija = false;
    });
    Tts.instance.speak(t.ar, id: 'yz-$_i');
  }

  void _keyingi() {
    if (_i + 1 >= _navbat.length) {
      setState(() => _tugadi = true);
      return;
    }
    setState(() {
      _i++;
      _urinish = 0;
      _natija = null;
      _korsatildi = false;
      _ctrl.clear();
    });
  }

  void _harfQosh(String h) {
    if (_natija == true) return;
    final v = _ctrl.value;
    final sel = v.selection.isValid
        ? v.selection
        : TextSelection.collapsed(offset: v.text.length);
    final yangi = v.text.replaceRange(sel.start, sel.end, h);
    _ctrl.value = TextEditingValue(
      text: yangi,
      selection: TextSelection.collapsed(offset: sel.start + h.length),
    );
    if (_natija == false) setState(() => _natija = null);
  }

  void _ochir() {
    final v = _ctrl.value;
    if (v.text.isEmpty) return;
    final sel = v.selection.isValid
        ? v.selection
        : TextSelection.collapsed(offset: v.text.length);
    if (sel.start != sel.end) {
      _ctrl.value = TextEditingValue(
        text: v.text.replaceRange(sel.start, sel.end, ''),
        selection: TextSelection.collapsed(offset: sel.start),
      );
    } else if (sel.start > 0) {
      // Harakat/harf — bitta kod nuqtasi.
      final chars = v.text.characters;
      final before = chars
          .take(v.text.substring(0, sel.start).characters.length - 1)
          .toString();
      final after = v.text.substring(sel.start);
      _ctrl.value = TextEditingValue(
        text: before + after,
        selection: TextSelection.collapsed(offset: before.length),
      );
    }
    if (_natija == false) setState(() => _natija = null);
  }

  /// Fatha, kasra, damma, sukun, shadda, tanvinlar.
  static const _harakatlar = ['َ', 'ِ', 'ُ', 'ْ', 'ّ', 'ً', 'ٍ', 'ٌ'];

  static const _harflar = [
    'ا',
    'ب',
    'ت',
    'ث',
    'ج',
    'ح',
    'خ',
    'د',
    'ذ',
    'ر',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ع',
    'غ',
    'ف',
    'ق',
    'ك',
    'ل',
    'م',
    'ن',
    'ه',
    'و',
    'ي',
    'ة',
    'ء',
    'ى',
    'أ',
    'إ',
    'آ',
    'ؤ',
    'ئ',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sarlavha)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _navbat.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Topshiriq yo\'q.'),
                )
              : _tugadi
              ? _yakun()
              : _mashq(),
        ),
      ),
    );
  }

  Widget _mashq() {
    final t = _t;
    final rang = switch (_natija) {
      true => AppColors.success,
      false => AppColors.coral,
      null => AppColors.chiziq2,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            const Icon(Icons.edit_rounded, size: 18, color: AppColors.indigo),
            const SizedBox(width: 6),
            Text(
              widget.jumla ? 'Jumlani arabcha yozing' : 'Arabchasini yozing',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Text(
              '${_i + 1} / ${_navbat.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBar(
          value: (_i + (_natija == true ? 1 : 0)) / _navbat.length,
          height: 6,
          color: AppColors.indigo,
          background: AppColors.indigo.withValues(alpha: 0.12),
        ),
        const SizedBox(height: 16),
        // Savol — faqat o'zbekcha va ovoz. Arabcha hech qayerda yo'q.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.karta,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.uz,
                  style: TextStyle(
                    fontSize: widget.jumla ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
              ),
              SpeakButton(
                text: t.ar,
                id: 'yz-$_i',
                size: 26,
                tooltip: 'Eshitish',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Portlash(
          trigger: _portlash == 0 ? null : _portlash,
          ranglar: const [AppColors.success, AppColors.gold, AppColors.emerald],
          child: Shake(
            trigger: _silkin == 0 ? null : _silkin,
            child: Container(
              decoration: BoxDecoration(
                color: _natija == true
                    ? AppColors.success.withValues(alpha: 0.10)
                    : AppColors.karta,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: rang, width: 1.6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                readOnly: _natija == true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: widget.jumla ? 3 : 1,
                onChanged: (_) {
                  if (_natija == false) setState(() => _natija = null);
                },
                onSubmitted: (_) => _tekshir(),
                style: AppTheme.arabic(
                  size: widget.jumla ? 26 : 34,
                  color: _natija == true
                      ? AppColors.success
                      : AppColors.emerald,
                  w: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '…',
                  hintStyle: TextStyle(color: AppColors.matn3),
                ),
              ),
            ),
          ),
        ),
        // «Bilmadim» dan keyin — to'g'ri javob (imtihon shu so'z uchun
        // tugadi; so'z keyinroq yana so'raladi).
        if (_korsatildi)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "To'g'ri javob — eslab qoling, keyinroq yana so'raladi:",
                    style: TextStyle(fontSize: 12.5, color: AppColors.matn2),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    t.ar,
                    style: AppTheme.arabic(
                      size: widget.jumla ? 22 : 30,
                      color: AppColors.gold,
                      w: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text(
          switch (_natija) {
            true => _urinish == 0 ? "To'g'ri! Birinchi urinishda." : "To'g'ri.",
            false =>
              _korsatildi
                  ? "Ko'rib qo'ying — keyin «Keyingisi»."
                  : "Xato — yana urinib ko'ring. Eshitish uchun karnayni bosing.",
            null =>
              "Javob ko'rsatilmaydi — o'zingiz eslang va yozing. Harakatsiz yozsangiz ham bo'ladi.",
          },
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _natija == false ? AppColors.coral : AppColors.matn2,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 12),
        if (_natija != true && !_korsatildi) ...[
          // Arab klaviaturasi — to'liq alifbo (variant emas).
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final h in _harflar) _tugma(h, () => _harfQosh(h)),
                // Harakatlar — ixtiyoriy (tekshiruv harakatsiz ham qabul
                // qiladi), lekin harakat bilan yozish odat bo'lsin.
                for (final h in _harakatlar)
                  _tugma('◌$h', () => _harfQosh(h), harakat: true),
                _tugma(
                  ' ',
                  () => _harfQosh(' '),
                  keng: true,
                  belgi: 'bo\'sh joy',
                ),
                _tugma('⌫', _ochir, keng: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _tekshir,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Tekshirish',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: _bilmadim,
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text("Bilmadim — javobni ko'rsat"),
                style: TextButton.styleFrom(foregroundColor: AppColors.gold),
              ),
            ],
          ),
        ],
        if (_natija == true || _korsatildi)
          PressableScale(
            child: FilledButton.icon(
              onPressed: _keyingi,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _i + 1 >= _navbat.length ? 'Yakunlash' : 'Keyingisi',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _tugma(
    String h,
    VoidCallback onTap, {
    bool keng = false,
    bool harakat = false,
    String? belgi,
  }) => Material(
    color: harakat
        ? AppColors.gold.withValues(alpha: 0.16)
        : AppColors.softGreen,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: keng ? 92 : 40,
        height: 44,
        alignment: Alignment.center,
        child: belgi != null
            ? Text(
                belgi,
                style: TextStyle(fontSize: 12, color: AppColors.matn2),
              )
            : Text(
                h,
                style: h == '⌫'
                    ? const TextStyle(fontSize: 20, color: AppColors.coral)
                    : AppTheme.arabic(size: 22, color: AppColors.zumradMatn),
              ),
      ),
    ),
  );

  Widget _yakun() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Reveal(
          fromScale: 0.6,
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 96,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_navbat.length} ta topshiriq',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Birinchi urinishda to\'g\'ri: $_togri / ${_navbat.length}',
          style: TextStyle(fontSize: 16, color: AppColors.matn2),
        ),
        if (_bilmaganlar.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Ishlash kerak (${_bilmaganlar.length}):',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final t in _bilmaganlar)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.uz,
                            style: TextStyle(color: AppColors.matn2),
                          ),
                        ),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            t.ar,
                            style: AppTheme.arabic(
                              size: 22,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        SpeakButton(text: t.ar, id: 'yz-x-${t.ar}', size: 18),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
          child: const Text('Qaytish'),
        ),
      ],
    ),
  );
}
