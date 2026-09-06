import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart'
    show
        BuildContext,
        StatelessWidget,
        StrutStyle,
        TextAlign,
        TextDirection,
        TextOverflow,
        TextScaler,
        TextStyle,
        Widget;

import '../uz_yozuv.dart';

/// Flutter'ning `Text` vidjetini almashtiradigan nusxa: matnni ekranga
/// chiqarishdan oldin tanlangan yozuvga ([uz]) o'giradi.
///
/// Nega shunday: ilovada 270 dan ortiq matn joyi bor. Har birini qo'lda
/// `Text(uz('...'))` deb o'rash — yangi yozilgan har bir satrda unutilishi
/// aniq bo'lgan qoida. Buning o'rniga fayl boshida
/// `import 'package:flutter/material.dart' hide Text;` deb yoziladi va
/// mana shu `Text` ishlatiladi — o'girish bir joyda, unutib bo'lmaydi.
///
/// Lotin tanlangan bo'lsa [uz] matnni o'zgarishsiz qaytaradi, ya'ni bu
/// qatlam faqat kirill rejimida ishlaydi. Arabcha matn (lotin harflari
/// yo'q) ikkala rejimda ham o'zgarmaydi.
///
/// Har bir `Text` yozuv o'zgarishini O'ZI tinglaydi. Ilova ildizidan
/// (`MaterialApp`) qayta chizish yetarli emas edi: `home: const
/// HomeScreen()` — const vidjet har rebuild'da AYNAN o'sha nusxa bo'lib
/// qoladi va Flutter uning ostidagi butun shoxni chizmasdan o'tkazib
/// yuboradi. Xuddi shu sabab Navigator ustiga qo'yilgan ekranlar ham
/// ildiz rebuild'idan xabar topmaydi. Har bir matn o'zi obuna bo'lsa,
/// tugma bosilishi bilan ochiq turgan ekran ham darrov o'giriladi.
class Text extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final StrutStyle? strutStyle;
  final TextScaler? textScaler;
  final String? semanticsLabel;

  const Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.strutStyle,
    this.textScaler,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return m.ListenableBuilder(
      listenable: UzYozuv.instance,
      builder: (context, _) => m.Text(
        uz(data),
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        strutStyle: strutStyle,
        textScaler: textScaler,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}

/// Yozuvga qarab O'GIRILMAYDIGAN matn.
///
/// Bitta joyda kerak bo'ladi: yozuvni almashtiruvchi tugmaning yozuvi.
/// U doim o'zi olib boradigan yozuvda turishi kerak — kirill rejimida
/// «Lotin» deb, lotin rejimida «Кирилл» deb. O'girilsa, tugma ikkala
/// rejimda ham bir xil ko'rinib, ma'nosini yo'qotardi.
class XomText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  const XomText(this.data, {super.key, this.style});

  @override
  Widget build(BuildContext context) => m.Text(data, style: style);
}
