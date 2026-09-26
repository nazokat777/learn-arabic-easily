/// Brauzer eslatmasi (Notification API). Web'dan boshqa joyda — jim.
///
/// Cheklov: eslatma faqat ilova (sayt) ochiq turganda chiqadi — yopiq
/// brauzerga xabar yuborish uchun push-server kerak, bizda yo'q.
library;

export 'eslatma_stub.dart' if (dart.library.js_interop) 'eslatma_web.dart';
