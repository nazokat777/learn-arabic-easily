import 'package:flutter/material.dart' hide Text;

import '../services/kirish.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ornament.dart';
import '../widgets/uz_text.dart';

/// Kirish kodi ekrani — sayt ochilganda birinchi ko'rinadigan narsa.
///
/// Sokin va qisqa: bitta maydon, bitta tugma. Xato kodda maydon
/// silkinadi va izoh chiqadi; to'g'risida darrov ilova ochiladi va
/// keyingi safar so'ralmaydi.
/// «Bog'lanish» havolasi — kirish.json'dagi «aloqa» bo'sh bo'lmasa chiqadi.
class _AloqaHavolasi extends StatelessWidget {
  const _AloqaHavolasi();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: Kirish.aloqaniOqi(),
      builder: (context, s) {
        final url = s.data ?? '';
        if (url.isEmpty) return const SizedBox.shrink();
        return TextButton.icon(
          onPressed: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text(
            "Bog'lanish",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: TextButton.styleFrom(foregroundColor: AppColors.emerald),
        );
      },
    );
  }
}

class KirishEkrani extends StatefulWidget {
  final String kod;
  final VoidCallback onKirdi;

  const KirishEkrani({super.key, required this.kod, required this.onKirdi});

  @override
  State<KirishEkrani> createState() => _KirishEkraniState();
}

class _KirishEkraniState extends State<KirishEkrani> {
  final _c = TextEditingController();
  bool _xato = false;
  int _silkin = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _tekshir() async {
    if (Kirish.togrimi(_c.text, widget.kod)) {
      Haptic.ok();
      await Kirish.eslabQol(widget.kod);
      widget.onKirdi();
      return;
    }
    Haptic.wrong();
    setState(() {
      _xato = true;
      _silkin++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: Aurora(
              colors: [AppColors.emerald, AppColors.gold, AppColors.teal],
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Reveal(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: BoxDecoration(
                        color: AppColors.karta,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GlowRing(
                            size: 88,
                            color: AppColors.emerald,
                            child: Text(
                              'ع',
                              style: AppTheme.arabic(
                                size: 40,
                                color: AppColors.emerald,
                                w: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Arab tilini oson o'rganamiz",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Bu sayt o'quv guruhi uchun. Kirish kodini "
                            "kiriting — bir marta so'raladi.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.matn2,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Kod qayerdan olinishi shu yerda aytiladi — yangi
                          // kursdosh yopiq eshik oldida qolib ketmasin.
                          Text(
                            "Kodni ustozingizdan yoki kurs guruhidan so'rang.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.matn3,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                          const _AloqaHavolasi(),
                          const SizedBox(height: 18),
                          const OrnamentDivider(),
                          const SizedBox(height: 18),
                          Shake(
                            trigger: _silkin == 0 ? null : _silkin,
                            child: TextField(
                              controller: _c,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              onSubmitted: (_) => _tekshir(),
                              onChanged: (_) {
                                if (_xato) setState(() => _xato = false);
                              },
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Kirish kodi',
                                errorText: _xato
                                    ? "Kod noto'g'ri. Kodni ustozingiz yoki kurs guruhidan oling."
                                    : null,
                                filled: true,
                                fillColor: AppColors.cream,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: Tactile(
                              child: FilledButton.icon(
                                onPressed: _tekshir,
                                icon: const Icon(Icons.login_rounded),
                                label: const Text(
                                  'Kirish',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.emerald,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Darvoza: kod kerak bo'lsa [KirishEkrani], aks holda [child].
class KirishDarvozasi extends StatefulWidget {
  final String kod;
  final bool kerak;
  final Widget child;

  const KirishDarvozasi({
    super.key,
    required this.kod,
    required this.kerak,
    required this.child,
  });

  @override
  State<KirishDarvozasi> createState() => _KirishDarvozasiState();
}

class _KirishDarvozasiState extends State<KirishDarvozasi> {
  late bool _kerak = widget.kerak;

  @override
  Widget build(BuildContext context) {
    if (!_kerak) return widget.child;
    return KirishEkrani(
      kod: widget.kod,
      onKirdi: () => setState(() => _kerak = false),
    );
  }
}
