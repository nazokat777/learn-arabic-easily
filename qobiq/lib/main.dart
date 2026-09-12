import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// «Arab tili» — yupqa qobiq.
///
/// Ilovaning o'zi saytda (Flutter web); bu APK uni telefon ichida ochadi.
/// Nega shunday: Android o'rnatilgan ilovaning KODINI tashqaridan
/// yangilashga yo'l qo'ymaydi — har yangi ekran uchun APKni qayta
/// o'rnatish kerak bo'lardi. Qobiq esa kodni ham, darslarni ham, ovozni
/// ham saytdan oladi: bir marta o'rnatiladi, keyin abadiy yangi turadi.
///
/// Progress (ball, seriya, yodlangan so'zlar) WebView'ning localStorage'ida
/// — ilova o'chirilmaguncha saqlanadi.
const String saytManzili = 'https://nazokat777.github.io/learn-arabic-easily/';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0E7C66),
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const QobiqIlova());
}

class QobiqIlova extends StatelessWidget {
  const QobiqIlova({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Arab tilini oson o'rganamiz",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0E7C66),
        scaffoldBackgroundColor: const Color(0xFFF7F3E9),
      ),
      home: const SaytEkrani(),
    );
  }
}

class SaytEkrani extends StatefulWidget {
  const SaytEkrani({super.key});

  @override
  State<SaytEkrani> createState() => _SaytEkraniState();
}

class _SaytEkraniState extends State<SaytEkrani> {
  late final WebViewController _c;
  bool _yuklanmoqda = true;
  bool _xato = false;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF7F3E9))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _yuklanmoqda = true;
            _xato = false;
          }),
          onPageFinished: (_) => setState(() => _yuklanmoqda = false),
          onWebResourceError: (e) {
            // Faqat asosiy sahifa ochilmasa — «internet yo'q» ekrani.
            // Bitta ovoz klipi yuklanmasa ilova to'xtamasin.
            if (e.isForMainFrame ?? true) {
              setState(() {
                _xato = true;
                _yuklanmoqda = false;
              });
            }
          },
          onNavigationRequest: (r) {
            // Sayt ichida — ilovada; tashqi havolalar ham shu oynada
            // (alohida brauzer ochilib, o'quvchi adashib qolmasin).
            return NavigationDecision.navigate;
          },
        ),
      );
    // Ovoz: foydalanuvchi tugma bosgach, keyingi kliplar «ishora»siz
    // ham chalinsin (mashqda «eshiting va toping» avtomatik o'qiydi).
    final platform = _c.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
    _c.loadRequest(Uri.parse(saytManzili));
  }

  Future<void> _orqaga(bool didPop, Object? _) async {
    if (didPop) return;
    if (await _c.canGoBack()) {
      await _c.goBack();
      return;
    }
    if (mounted) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _orqaga,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _c),
              if (_yuklanmoqda && !_xato)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0E7C66)),
                ),
              if (_xato) _InternetYoq(onQayta: () => _c.reload()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internet yo'q — sokin, aniq, bitta tugma.
class _InternetYoq extends StatelessWidget {
  final VoidCallback onQayta;
  const _InternetYoq({required this.onQayta});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F3E9),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Color(0xFF0E7C66)),
          const SizedBox(height: 16),
          const Text(
            "Internet yo'q",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            "Darslar va ovoz saytdan keladi. Internetni yoqib, qayta urinib ko'ring.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onQayta,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Qayta urinish'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0E7C66),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
