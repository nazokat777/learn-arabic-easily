import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter/widgets.dart';

/// Sahifa manzili (URL) — dars ochilganda brauzer manzili `#/modul/id`
/// ko'rinishida yangilanadi; yangilash (F5) yoki havola orqali o'sha dars
/// qayta ochiladi.
///
/// Nega router emas: butun ilova `Navigator.push` bilan yozilgan (40 dan
/// ortiq joy). Ularni router'ga ko'chirish katta o'zgarish; bu yerda esa
/// manzil faqat DARS darajasida yuritiladi — audit'dagi asosiy ehtiyoj
/// (yangilashda joyni yo'qotmaslik, havola ulashish) shu bilan yopiladi.
class Manzil {
  Manzil._();

  /// Brauzer manzilini `#/modul/id` qiladi (faqat web; boshqa joyda jim).
  static void yangila(String modul, String id) {
    if (!kIsWeb) return;
    // Boshida «/» bo'lsin: brauzerda `#/nahv/nahv-1-3` ko'rinadi.
    SystemNavigator.routeInformationUpdated(
      uri: Uri(path: '/$modul/${Uri.encodeComponent(id)}'),
    );
  }

  /// Bosh ekranga qaytilganda manzil `#/` ga tushadi.
  static void tozala() {
    if (!kIsWeb) return;
    SystemNavigator.routeInformationUpdated(uri: Uri(path: '/'));
  }

  /// Manzil bo'lagini (`/nahv/nahv-1-5`) modul va id'ga ajratadi.
  /// Noto'g'ri yoki bo'sh bo'lsa `null`.
  static (String, String)? ajrat(String bolak) {
    final qismlar = bolak
        .split('/')
        .map(Uri.decodeComponent)
        .where((q) => q.isNotEmpty)
        .toList();
    if (qismlar.length != 2) return null;
    const modullar = {'alifbo', 'qiroat', 'nahv', 'sarf'};
    if (!modullar.contains(qismlar[0])) return null;
    return (qismlar[0], qismlar[1]);
  }

  /// Ilova ochilgandagi manzil (web'da `Uri.base` bo'lagi).
  static (String, String)? boshlangich() {
    if (!kIsWeb) return null;
    return ajrat(Uri.base.fragment);
  }
}

/// Bosh ekranga qaytilganda manzilni tozalaydigan kuzatuvchi.
class ManzilKuzatuvchi extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && previousRoute.isFirst) Manzil.tozala();
  }
}
