import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_arabic/theme.dart';

/// Qorong'u rejim: palitra almashadi va qaytadi; brend ranglari o'zgarmaydi.
void main() {
  test("rejim almashganda sirt ranglari o'zgaradi, brend ranglari qoladi", () {
    AppColors.rejim(false);
    expect(AppColors.karta, Colors.white);
    expect(AppColors.qorongu, isFalse);
    final oldinEmerald = AppColors.emerald;
    AppColors.rejim(true);
    expect(AppColors.qorongu, isTrue);
    expect(AppColors.karta, isNot(Colors.white));
    expect(
      AppColors.ink.computeLuminance(),
      greaterThan(0.5),
      reason: "qorong'uda matn yorug'",
    );
    expect(
      AppColors.cream.computeLuminance(),
      lessThan(0.1),
      reason: "qorong'uda fon to'q",
    );
    expect(AppColors.emerald, oldinEmerald);
    AppColors.rejim(false);
    expect(AppColors.ink.computeLuminance(), lessThan(0.1));
  });

  test("arabic() rang berilmasa joriy matn rangini oladi", () {
    AppColors.rejim(true);
    expect(AppTheme.arabic().color, AppColors.ink);
    AppColors.rejim(false);
  });
}
