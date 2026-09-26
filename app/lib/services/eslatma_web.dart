import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('Notification')
extension type _Notif._(JSObject _) implements JSObject {
  external factory _Notif(String title, _Opts opts);
  external static String get permission;
  external static JSPromise<JSString> requestPermission();
}

extension type _Opts._(JSObject _) implements JSObject {
  external factory _Opts({String body, String tag});
}

bool eslatmaQollanadi() => globalContext.has('Notification');

/// 'granted' | 'denied' | 'default'
String eslatmaRuxsati() =>
    eslatmaQollanadi() ? _Notif.permission : 'denied';

Future<bool> eslatmaRuxsatSora() async {
  if (!eslatmaQollanadi()) return false;
  try {
    final r = await _Notif.requestPermission().toDart;
    return r.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

void eslatmaKorsat(String sarlavha, String matn) {
  if (!eslatmaQollanadi() || _Notif.permission != 'granted') return;
  try {
    _Notif(sarlavha, _Opts(body: matn, tag: 'mnemonika-reja'));
  } catch (_) {}
}
