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

// serviceWorker sozlamasisiz chaqirilsa, Flutter SW ro'yxatdan o'tkazmaydi.
_flutter.loader.load();
