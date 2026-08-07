import 'package:flutter/material.dart';
import '../main.dart';
import '../content.dart';
import '../theme.dart';

class HarakatLesson extends StatelessWidget {
  const HarakatLesson({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Harakatlar darsi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Harakatlar — harf ustidagi yoki ostidagi kichik belgilar. Ular harfning tovushini belgilaydi. Quyida "baa" (ب) harfida ko\'ring:',
              style: TextStyle(color: AppColors.ink, height: 1.35),
            ),
          ),
          const SizedBox(height: 16),
          ...repo.harakat.map((h) => _card(h)),
        ],
      ),
    );
  }

  Widget _card(Haraka h) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(h.exampleAr, style: AppTheme.arabic(size: 42, color: AppColors.emerald)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(h.nameUz,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('«${h.soundUz}»',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.gold, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(h.descUz, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
