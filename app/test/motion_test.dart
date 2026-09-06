import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/widgets/motion.dart';

/// Motion vidjetlari — brauzerda «kulrang quti» bo'lib chiqqan xatolar
/// (masalan, Positioned Stack'ning bevosita bolasi bo'lmasa) debug'da
/// exception beradi. Bu testlar har animatsiyani boshidan oxirigacha
/// pump qilib, shunday xatolarni releasedan oldin ushlaydi.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('XpChip: qiymat oshganda +N chiqadi va xatosiz o\'tadi', (
    t,
  ) async {
    await t.pumpWidget(host(const XpChip(value: 0)));
    expect(find.textContaining('XP'), findsOneWidget);
    await t.pumpWidget(host(const XpChip(value: 3)));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('+3'), findsOneWidget);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    // Animatsiya tugagach yozuv yo'qoladi.
    expect(find.text('+3'), findsNothing);
  });

  testWidgets('FlipCard: flipped o\'zgarganda orqa tomon ko\'rinadi', (
    t,
  ) async {
    Widget card(bool flipped) => host(
      SizedBox(
        width: 200,
        height: 200,
        child: FlipCard(
          flipped: flipped,
          front: const Text('OLD'),
          back: const Text('ORQA'),
        ),
      ),
    );
    await t.pumpWidget(card(false));
    expect(find.text('OLD'), findsOneWidget);
    expect(find.text('ORQA'), findsNothing);
    await t.pumpWidget(card(true));
    await t.pumpAndSettle();
    expect(find.text('ORQA'), findsOneWidget);
    expect(find.text('OLD'), findsNothing);
    // Qaytarish ham ishlaydi.
    await t.pumpWidget(card(false));
    await t.pumpAndSettle();
    expect(find.text('OLD'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('SlideSwitch: kalit o\'zgarganda yangi bola keladi', (t) async {
    Widget sw(String k) => host(
      SlideSwitch(
        child: KeyedSubtree(key: ValueKey(k), child: Text(k)),
      ),
    );
    await t.pumpWidget(sw('bir'));
    await t.pumpWidget(sw('ikki'));
    await t.pump(const Duration(milliseconds: 100));
    // O'tish paytida ikkalasi ham daraxtda (eskisi so'nmoqda).
    expect(find.text('ikki'), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.text('bir'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('SlideSwitch expand: Expanded ichida to\'liq joy egallaydi', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        SizedBox(
          width: 300,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: SlideSwitch(
                  expand: true,
                  child: Container(
                    key: const ValueKey('k'),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final size = t.getSize(find.byKey(const ValueKey('k')));
    expect(size.height, 400);
    expect(size.width, 300);
  });

  testWidgets('Pulse/Shake: trigger null→qiymat o\'ynaydi, xatosiz', (t) async {
    Widget w(Object? trig) => host(
      Pulse(
        trigger: trig,
        child: Shake(trigger: trig, child: const Text('X')),
      ),
    );
    await t.pumpWidget(w(null));
    await t.pumpWidget(w(1));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
