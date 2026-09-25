import 'package:flutter/material.dart' hide Text;

import '../services/tts.dart';
import '../theme.dart';
import '../ustoz/bilim_bazasi.dart';
import '../ustoz/javob_dvigateli.dart';
import '../widgets/entrance.dart';
import '../widgets/harflab_qatori.dart';
import '../widgets/speak_button.dart';
import '../widgets/uz_text.dart';

/// USTOZ — butun ilova bo'yicha savol-javob.
///
/// Uch ish qiladi: arabchani o'zbekchaga, o'zbekchani arabchaga o'giradi va
/// grammatika savollariga Nahv/Sarf kitoblari hamda Sharh qatlamidan javob
/// beradi. Har javob ostida MANBA turadi (qaysi kitob, qaysi dars) — o'quvchi
/// tekshira oladi, ustoz esa «o'zidan» gapirmaydi.
///
/// Internet kerak emas: javob qurilmadagi kitob matnidan qidiriladi.
class UstozEkrani extends StatefulWidget {
  const UstozEkrani({super.key});

  @override
  State<UstozEkrani> createState() => _UstozEkraniState();
}

class _Xabar {
  final bool meniki;
  final String savol;
  final Javob? javob;
  const _Xabar.savol(this.savol) : meniki = true, javob = null;
  const _Xabar.javob(this.javob) : meniki = false, savol = '';
}

class _UstozEkraniState extends State<UstozEkrani> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Xabar> _tarix = [];
  bool _ishlayapti = false;

  static const _namunalar = [
    'مَا الْفَاعِلُ؟',
    'Majhul fe\'l nima?',
    'Kitob stol ustida',
    'أَيْنَ الْكِتَابُ؟',
    'Jazm qachon bo\'ladi?',
    'Ismi foil qanday yasaladi?',
  ];

  @override
  void initState() {
    super.initState();
    // Baza fon rejimida tayyorlanadi — birinchi savol tez javob olsin.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BilimBazasi.instance.tayyorla();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    Tts.instance.stop();
    super.dispose();
  }

  Future<void> _sora([String? matn]) async {
    final s = (matn ?? _ctrl.text).trim();
    if (s.isEmpty || _ishlayapti) return;
    setState(() {
      _tarix.add(_Xabar.savol(s));
      _ishlayapti = true;
      _ctrl.clear();
    });
    _pastga();
    // Qidiruv qurilmada — tez; kichik kechikish javob «yozilayotgandek»
    // ko'rinsin (o'quvchi savolini o'qib ulgursin).
    await Future.delayed(const Duration(milliseconds: 120));
    final j = JavobDvigateli.instance.javob(s);
    if (!mounted) return;
    setState(() {
      _tarix.add(_Xabar.javob(j));
      _ishlayapti = false;
    });
    _pastga();
  }

  void _pastga() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustoz — savol-javob')),
      body: Column(
        children: [
          Expanded(
            child: _tarix.isEmpty
                ? _kirish()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _tarix.length + (_ishlayapti ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _tarix.length) return _kutish();
                      final x = _tarix[i];
                      return x.meniki
                          ? _savolKartasi(x.savol)
                          : _javobKartasi(x.javob!);
                    },
                  ),
          ),
          _yozish(),
        ],
      ),
    );
  }

  Widget _kirish() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.softGreen,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.emerald),
                const SizedBox(width: 8),
                Text(
                  'Nima so\'rash mumkin?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _qator(
              Icons.translate_rounded,
              'Arabcha jumla yozing — o\'zbekchasini va so\'zma-so\'z tahlilini beradi',
            ),
            _qator(
              Icons.g_translate_rounded,
              'O\'zbekcha yozing — kitobdagi arabchasini topib beradi',
            ),
            _qator(
              Icons.menu_book_rounded,
              'Grammatika savoli — Nahv/Sarf kitobi va sharhdan javob (manbasi bilan)',
            ),
            const SizedBox(height: 6),
            Text(
              'Javoblar faqat ilovadagi kitoblardan olinadi — o\'ylab topilmaydi. '
              'Kitobda yo\'q bo\'lsa, shunday deb aytiladi.',
              style: TextStyle(fontSize: 12.5, color: AppColors.matn2),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Text(
        'Namuna savollar:',
        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final n in _namunalar)
            PressableScale(
              child: Material(
                color: AppColors.karta,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _sora(n),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(n, style: TextStyle(color: AppColors.ink)),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  Widget _qator(IconData i, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(i, size: 18, color: AppColors.emerald),
        const SizedBox(width: 8),
        Expanded(
          child: Text(t, style: TextStyle(color: AppColors.ink, height: 1.3)),
        ),
      ],
    ),
  );

  Widget _savolKartasi(String s) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10, left: 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.emerald,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 15)),
    ),
  );

  Widget _kutish() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.karta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );

  Widget _javobKartasi(Javob j) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 14, right: 20),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.karta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: j.aniq
              ? AppColors.success.withValues(alpha: 0.45)
              : AppColors.chiziq2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ishonch belgisi: kitobda aynan bormi yoki so'zma-so'z yig'ilganmi.
          Row(
            children: [
              Icon(
                j.aniq ? Icons.verified_rounded : Icons.info_outline_rounded,
                size: 16,
                color: j.aniq ? AppColors.success : AppColors.gold,
              ),
              const SizedBox(width: 6),
              Text(
                j.aniq ? 'Kitobdan' : 'Taxminiy (kitobda aynan yo\'q)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: j.aniq ? AppColors.success : AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (j.arabcha.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      j.arabcha,
                      style: AppTheme.arabic(
                        size: 26,
                        color: AppColors.emerald,
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SpeakButton(
                  text: j.arabcha,
                  id: 'ustoz-${j.arabcha}',
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            j.matn,
            style: TextStyle(color: AppColors.ink, height: 1.35, fontSize: 15),
          ),
          if (j.tahlil.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'So\'zma-so\'z:',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: AppColors.matn2,
              ),
            ),
            const SizedBox(height: 4),
            for (final t in j.tahlil)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        t.ar,
                        style: AppTheme.arabic(
                          size: 19,
                          color: AppColors.zumradMatn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.uz,
                        style: TextStyle(fontSize: 13, color: AppColors.matn2),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (j.arabcha.isNotEmpty && j.arabcha.split(' ').length == 1) ...[
            const SizedBox(height: 10),
            HarflabQatori(
              soz: j.arabcha,
              id: 'ustoz-h-${j.arabcha}',
              harfOlchami: 20,
            ),
          ],
          if (j.manbalar.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              'Manba (kitobdagi joyi):',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: AppColors.matn2,
              ),
            ),
            const SizedBox(height: 6),
            for (final p in j.manbalar.take(5)) _manbaQator(p),
          ],
        ],
      ),
    ),
  );

  Widget _manbaQator(Parcha p) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.softGreen.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.manba,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.emerald,
          ),
        ),
        if (p.ar.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    p.ar,
                    style: AppTheme.arabic(size: 18, color: AppColors.ink),
                  ),
                ),
              ),
              SpeakButton(text: p.ar, id: 'ustoz-m-${p.ar}', size: 16),
            ],
          ),
        if (p.uz.isNotEmpty)
          Text(
            p.uz,
            style: TextStyle(fontSize: 13, color: AppColors.matn2, height: 1.3),
          ),
      ],
    ),
  );

  Widget _yozish() => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    decoration: BoxDecoration(
      color: AppColors.karta,
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sora(),
              decoration: InputDecoration(
                hintText: 'Savol yozing yoki jumla kiriting…',
                hintStyle: TextStyle(color: AppColors.matn3, fontSize: 14),
                filled: true,
                fillColor: AppColors.cream,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            child: Material(
              color: AppColors.emerald,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _ishlayapti ? null : () => _sora(),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
