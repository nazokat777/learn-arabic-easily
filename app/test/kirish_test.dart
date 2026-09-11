import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/screens/kirish_ekrani.dart';
import 'package:learn_arabic/services/kirish.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kirish darvozasi: noto'g'ri kod o'tkazmaydi, to'g'risi ochadi va
/// eslab qolinadi.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test("kod solishtirish: bo'sh joy va katta-kichik harf farq qilmaydi", () {
    expect(Kirish.togrimi('  KursDosh ', 'kursdosh'), isTrue);
    expect(Kirish.togrimi('kursdoshlar', 'kursdosh'), isFalse);
  });

  testWidgets("noto'g'ri kod — xato izohi; to'g'ri kod — ilova ochiladi", (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: KirishDarvozasi(
          kod: 'kursdosh',
          kerak: true,
          child: Scaffold(body: Text('ILOVA')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('ILOVA'), findsNothing);

    await tester.enterText(find.byType(TextField), 'notogri');
    await tester.tap(find.text('Kirish'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining("noto'g'ri"), findsOneWidget);
    expect(find.text('ILOVA'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Kursdosh');
    await tester.tap(find.text('Kirish'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('ILOVA'), findsOneWidget);

    final p = await SharedPreferences.getInstance();
    expect(p.getString('kirishKodi'), 'kursdosh');
  });

  testWidgets('darvoza kerak bo\'lmasa ilova darrov ochiladi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: KirishDarvozasi(
          kod: 'kursdosh',
          kerak: false,
          child: Scaffold(body: Text('ILOVA')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('ILOVA'), findsOneWidget);
  });
}
