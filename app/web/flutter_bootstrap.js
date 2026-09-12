{{flutter_js}}
{{flutter_build_config}}

// Bu ilova doim eng yangi darslarni ko'rsatishi kerak.
// Flutter web'ning standart service worker'i kontentni keshlaydi va natijada
// foydalanuvchi har doim BIR QADAM ORQADAGI nusxani ko'radi (yangisi faqat
// keyingi ochilishda chiqadi). Shuning uchun service worker'ni umuman
// ro'yxatdan o'tkazmaymiz va avval o'rnatilgani bo'lsa, uni o'chiramiz.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations()
    .then(function (regs) { regs.forEach(function (r) { r.unregister(); }); })
    .catch(function () {});
}
if (window.caches && caches.keys) {
  caches.keys()
    .then(function (keys) { keys.forEach(function (k) { caches.delete(k); }); })
    .catch(function () {});
}

function holat(m) { if (window.pardaHolat) window.pardaHolat(m); }

// serviceWorker sozlamasisiz chaqirilsa, Flutter SW ro'yxatdan o'tkazmaydi.
// CanvasKit saytning o'zidan olinadi (gstatic CDN'ga bog'liq emas — ba'zi
// tarmoqlarda u sekin yoki yopiq). Har bosqichda parda matni yangilanadi.
holat('Ilova yuklanmoqda…');
_flutter.loader.load({
  // Diqqat: canvasKitBaseUrl shu yerda (loader config) berilishi shart —
  // initializeEngine'ga berilsa loader baribir gstatic'dan oladi.
  config: { canvasKitBaseUrl: 'canvaskit/' },
  onEntrypointLoaded: async function (engineInitializer) {
    holat('Chizish dvigateli tayyorlanmoqda…');
    var appRunner = await engineInitializer.initializeEngine();
    holat('Darslar yuklanmoqda…');
    await appRunner.runApp();
  }
});
