import 'package:flutter/material.dart';
import 'content.dart';
import 'progress.dart';
import 'theme.dart';
import 'screens/alifbo_home.dart';
import 'screens/qiroat_lessons.dart';
import 'screens/mashqlar_home.dart';
import 'widgets/entrance.dart';

late final ContentRepository repo;
late final Progress progress;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  repo = ContentRepository();
  progress = Progress();
  await repo.load();
  await progress.load();
  runApp(const ArabApp());
}

class ArabApp extends StatelessWidget {
  const ArabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Arab tilini oson o'rganamiz",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const EntranceFade(child: _Header()),
              const SizedBox(height: 20),
              const EntranceFade(delay: Duration(milliseconds: 60), child: XpPanel()),
              const SizedBox(height: 24),
              EntranceFade(
                delay: const Duration(milliseconds: 120),
                child: Text('Bo\'limlar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              const SizedBox(height: 12),
              EntranceFade(
                delay: const Duration(milliseconds: 180),
                child: ModuleCard(
                  title: 'Alifbo (Harflar)',
                  subtitle: 'Harf va talaffuz: 28 harf, махраж, harakatlar',
                  arabic: 'أ ب ت',
                  color: AppColors.emerald,
                  enabled: true,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AlifboHome())),
                ),
              ),
              const SizedBox(height: 12),
              EntranceFade(
                delay: const Duration(milliseconds: 240),
                child: ModuleCard(
                  title: 'Mabdaul qiroat',
                  subtitle: 'O\'qish asosi — 1 va 2-kitob',
                  arabic: 'اِقْرَأْ',
                  color: AppColors.emerald,
                  enabled: true,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const QiroatBooksHome())),
                ),
              ),
              const SizedBox(height: 12),
              EntranceFade(
                delay: const Duration(milliseconds: 300),
                child: ModuleCard(
                  title: 'Mashqlar',
                  subtitle: 'Lug\'at testi va so\'z yasash o\'yini',
                  arabic: 'تَمَارِين',
                  color: AppColors.gold,
                  enabled: true,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MashqlarHome())),
                ),
              ),
              const SizedBox(height: 12),
              EntranceFade(
                delay: const Duration(milliseconds: 360),
                child: ModuleCard(
                  title: 'Sarf',
                  subtitle: 'So\'z tuzilishi — vazn, tasrif, fe\'l boblari',
                  arabic: 'صَرْف',
                  color: AppColors.gold,
                  enabled: false,
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 12),
              EntranceFade(
                delay: const Duration(milliseconds: 420),
                child: ModuleCard(
                  title: 'Nahv',
                  subtitle: 'Jumla tuzilishi — i\'rob, amil-ma\'mul',
                  arabic: 'نَحْو',
                  color: AppColors.coral,
                  enabled: false,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.emerald, AppColors.emeraldDark]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text('ع',
                style: AppTheme.arabic(size: 30, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Arab tilini oson o\'rganamiz',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800, color: AppColors.ink)),
              Text('${progress.levelName} · ${progress.level}-daraja',
                  style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        _StreakBadge(streak: progress.streak),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          Text('$streak',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.coral)),
        ],
      ),
    );
  }
}

/// XP paneli — daraja va taraqqiyot chizig'i.
class XpPanel extends StatelessWidget {
  const XpPanel({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.emerald, AppColors.emeraldDark],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Umumiy XP',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              Text('${progress.xp} XP',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.levelProgress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 6),
          Text('Keyingi darajagacha: ${100 - progress.xpInLevel} XP',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class ModuleCard extends StatelessWidget {
  final String title, subtitle, arabic;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const ModuleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.arabic,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: PressableScale(
        child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: Text(arabic, style: AppTheme.arabic(size: 28, color: color))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.ink)),
                          if (!enabled) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.lock_outline, size: 15, color: Colors.grey),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(enabled ? Icons.chevron_right : Icons.hourglass_empty,
                    color: enabled ? color : Colors.grey),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
