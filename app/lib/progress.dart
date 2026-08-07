import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Foydalanuvchi taraqqiyoti: XP, olov (streak), tugatilgan darslar.
/// Mahalliy saqlanadi (shared_preferences) — offline ishlaydi.
class Progress extends ChangeNotifier {
  int xp = 0;
  int streak = 0;
  String? _lastActiveDay; // 'YYYY-MM-DD'
  final Set<String> _completed = {};

  SharedPreferences? _prefs;

  int get level => (xp ~/ 100) + 1;
  int get xpInLevel => xp % 100;
  double get levelProgress => xpInLevel / 100.0;

  static const List<String> levelNames = [
    'Mubtadi\'', 'Mubtadi\' +', 'Mutavassit', 'Mutavassit +', 'Mutaqaddim',
    'Mutaqaddim +', 'Muntahiy', 'Muntahiy +', 'Ustoz', 'Alloma',
  ];
  String get levelName => levelNames[(level - 1).clamp(0, levelNames.length - 1)];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    xp = _prefs!.getInt('xp') ?? 0;
    streak = _prefs!.getInt('streak') ?? 0;
    _lastActiveDay = _prefs!.getString('lastDay');
    _completed.addAll(_prefs!.getStringList('completed') ?? []);
    _refreshStreak();
    notifyListeners();
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _refreshStreak() {
    final today = _today();
    if (_lastActiveDay == null) return;
    if (_lastActiveDay == today) return;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final y = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    if (_lastActiveDay != y) {
      streak = 0; // seriya uzildi
    }
  }

  Future<void> addXp(int amount) async {
    xp += amount;
    final today = _today();
    if (_lastActiveDay != today) {
      streak += 1;
      _lastActiveDay = today;
    }
    await _save();
    notifyListeners();
  }

  bool isCompleted(String lessonId) => _completed.contains(lessonId);

  Future<void> markCompleted(String lessonId) async {
    _completed.add(lessonId);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt('xp', xp);
    await p.setInt('streak', streak);
    if (_lastActiveDay != null) await p.setString('lastDay', _lastActiveDay!);
    await p.setStringList('completed', _completed.toList());
  }
}
