import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import '../core/constants.dart';
import 'water_provider.dart';
import 'history_provider.dart';

/// State is a map of achievementId -> unlock date (ISO string).
class AchievementsNotifier extends StateNotifier<Map<String, String>> {
  final Ref _ref;
  Box? _box;

  AchievementsNotifier(this._ref) : super({}) {
    _init();
  }

  Future<void> _init() async {
    try {
      _box = await Hive.openBox(HiveBoxes.achievements);
      final saved = _box!.get('unlocked_dates');
      if (saved != null) {
        state = Map<String, String>.from(saved);
      } else {
        // Migrate from old format (list of strings) if present
        final oldList = _box!.get('unlocked');
        if (oldList != null) {
          final now = DateTime.now().toIso8601String();
          final migrated = <String, String>{};
          for (final id in List<String>.from(oldList)) {
            migrated[id] = now;
          }
          state = migrated;
          await _box!.put('unlocked_dates', state);
          await _box!.delete('unlocked');
        }
      }
    } catch (_) {}
  }

  Future<bool> _unlock(String id) async {
    if (state.containsKey(id)) return false;
    final now = DateTime.now().toIso8601String();
    state = {...state, id: now};
    try {
      await _box?.put('unlocked_dates', state);
    } catch (_) {}
    return true;
  }

  /// Check all achievements against current state. Returns newly unlocked ids.
  Future<List<String>> checkAll() async {
    final water = _ref.read(waterProvider);
    final newlyUnlocked = <String>[];

    if (water.currentCount >= 1) {
      if (await _unlock('first_glass')) newlyUnlocked.add('first_glass');
    }

    if (water.goalMet) {
      if (await _unlock('goal_met')) newlyUnlocked.add('goal_met');
    }

    if (water.currentCount >= water.dailyGoal * 2) {
      if (await _unlock('double_goal')) newlyUnlocked.add('double_goal');
    }

    if (water.currentMl >= 1000) {
      if (await _unlock('liter')) newlyUnlocked.add('liter');
    }

    try {
      final service = _ref.read(historyServiceProvider);
      final allRecords = await service.getRecentDays(365);
      final totalGlasses = allRecords.fold<int>(0, (s, r) => s + r.glasses);

      if (totalGlasses >= 50) {
        if (await _unlock('glasses_50')) newlyUnlocked.add('glasses_50');
      }
      if (totalGlasses >= 100) {
        if (await _unlock('glasses_100')) newlyUnlocked.add('glasses_100');
      }
      if (totalGlasses >= 500) {
        if (await _unlock('glasses_500')) newlyUnlocked.add('glasses_500');
      }

      final streak = await _ref.read(streakProvider.future);
      if (streak >= 3) {
        if (await _unlock('streak_3')) newlyUnlocked.add('streak_3');
      }
      if (streak >= 7) {
        if (await _unlock('streak_7')) newlyUnlocked.add('streak_7');
      }
      if (streak >= 14) {
        if (await _unlock('streak_14')) newlyUnlocked.add('streak_14');
      }
      if (streak >= 30) {
        if (await _unlock('streak_30')) newlyUnlocked.add('streak_30');
      }
    } catch (_) {}

    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 5) {
      if (await _unlock('night_owl')) newlyUnlocked.add('night_owl');
    }
    if (hour >= 5 && hour < 7) {
      if (await _unlock('early_bird')) newlyUnlocked.add('early_bird');
    }

    return newlyUnlocked;
  }

  Future<bool> unlockManual(String id) => _unlock(id);
}

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, Map<String, String>>((ref) {
  return AchievementsNotifier(ref);
});
