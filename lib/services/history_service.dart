import 'package:hive_ce/hive.dart';
import '../core/constants.dart';
import '../models/day_record.dart';

/// Hive-backed CRUD for daily history records.
class HistoryService {
  Box<DayRecord>? _box;

  Future<Box<DayRecord>> get box async {
    _box ??= await Hive.openBox<DayRecord>(HiveBoxes.history);
    return _box!;
  }

  /// Save (or overwrite) a day's record.
  Future<void> saveDay(DayRecord record) async {
    final b = await box;
    await b.put(record.dateKey, record);
  }

  /// Get a single day's record.
  Future<DayRecord?> getDay(String dateKey) async {
    final b = await box;
    return b.get(dateKey);
  }

  /// Get records for the last [days] days, ordered newest first.
  Future<List<DayRecord>> getRecentDays(int days) async {
    final b = await box;
    final results = <DayRecord>[];
    final now = DateTime.now();
    for (var i = 0; i < days; i++) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final record = b.get(key);
      if (record != null) {
        results.add(record);
      }
    }
    return results;
  }

  /// Current streak: consecutive days meeting the goal, ending today or yesterday.
  /// [freezesAvailable] allows skipping missed days without breaking the streak.
  Future<int> calculateStreak({int freezesAvailable = 0}) async {
    final b = await box;
    var streak = 0;
    var freezesUsed = 0;
    final now = DateTime.now();
    for (var i = 0; i < 365; i++) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final record = b.get(key);
      if (record != null && record.goalMet) {
        streak++;
      } else if (i == 0) {
        // Today doesn't count if not met yet — continue checking from yesterday.
        continue;
      } else if (freezesUsed < freezesAvailable) {
        // Use a streak freeze for this missed day
        freezesUsed++;
        streak++; // The frozen day still counts toward the streak
      } else {
        break;
      }
    }
    return streak;
  }

  /// Average ml per day over the last [days] days.
  Future<double> averageMl(int days) async {
    final records = await getRecentDays(days);
    if (records.isEmpty) return 0;
    final total = records.fold<int>(0, (sum, r) => sum + r.totalMl);
    return total / records.length;
  }

  /// Get ALL records in the box.
  Future<List<DayRecord>> getAllRecords() async {
    final b = await box;
    return b.values.toList();
  }

  /// Prune records older than [keepDays].
  Future<void> prune(int keepDays) async {
    final b = await box;
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    final keysToRemove = <String>[];
    for (final key in b.keys.cast<String>()) {
      final d = DateTime.tryParse(key);
      if (d != null && d.isBefore(cutoff)) {
        keysToRemove.add(key);
      }
    }
    await b.deleteAll(keysToRemove);
  }
}
