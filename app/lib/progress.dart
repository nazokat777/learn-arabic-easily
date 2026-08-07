import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Foydalanuvchi taraqqiyoti: XP, olov (streak), tugatilgan darslar,
/// va har bir so'z uchun yodlash darajasi.
/// Mahalliy saqlanadi (shared_preferences) — offline ishlaydi.
class Progress extends ChangeNotifier {
  /// So'z «yodlangan» hisoblanishi uchun nechta marta to'g'ri javob kerak.
  static const int masteryGoal = 5;

  int xp = 0;
  int streak = 0;
  String? _lastActiveDay; // 'YYYY-MM-DD'
  final Set<String> _completed = {};
  // Har bir so'z uchun to'g'ri javoblar soni (0..masteryGoal). Kalit: darsId::arabcha
  final Map<String, int> _mastery = {};

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
    final ms = _prefs!.getString('mastery');
    if (ms != null) {
      (json.decode(ms) as Map).forEach((k, v) => _mastery[k as String] = (v as num).toInt());
    }
    _refreshStreak();
    notifyListeners();
  }

  /// So'zning yodlash darajasi (0..masteryGoal).
  int wordMastery(String key) => _mastery[key] ?? 0;

  /// So'z to'liq yodlanganmi (masteryGoal marta to'g'ri).
  bool isWordLearned(String key) => (_mastery[key] ?? 0) >= masteryGoal;

  /// To'g'ri javobda +1, xatoda -1 (0..masteryGoal orasida). Yangi darajani qaytaradi.
  Future<int> bumpWord(String key, bool correct) async {
    final cur = _mastery[key] ?? 0;
    final next = (correct ? cur + 1 : cur - 1).clamp(0, masteryGoal);
    _mastery[key] = next;
    await _save();
    notifyListeners();
    return next;
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
    await p.setString('mastery', json.encode(_mastery));
  }
}
