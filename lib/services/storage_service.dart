import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/date_utils.dart';

/// Wraps SharedPreferences for today's water data.
/// This is the source of truth shared with the native Android widget.
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // --- Current count ---

  int get currentCount => _prefs.getInt(SPKeys.currentCount) ?? 0;

  Future<void> setCurrentCount(int count) async {
    await _prefs.setInt(SPKeys.currentCount, count);
  }

  // --- Daily goal ---

  int get dailyGoal => _prefs.getInt(SPKeys.dailyGoal) ?? Defaults.dailyGoal;

  Future<void> setDailyGoal(int goal) async {
    await _prefs.setInt(SPKeys.dailyGoal, goal);
  }

  // --- Glass size ---

  int get glassSizeMl =>
      _prefs.getInt(SPKeys.glassSizeMl) ?? Defaults.glassSizeMl;

  Future<void> setGlassSizeMl(int ml) async {
    await _prefs.setInt(SPKeys.glassSizeMl, ml);
  }

  // --- Last reset date ---

  String? get lastResetDate => _prefs.getString(SPKeys.lastResetDate);

  Future<void> setLastResetDate(String dateKey) async {
    await _prefs.setString(SPKeys.lastResetDate, dateKey);
  }

  // --- Premium ---

  bool get isPremium => _prefs.getBool(SPKeys.isPremium) ?? false;

  Future<void> setIsPremium(bool value) async {
    await _prefs.setBool(SPKeys.isPremium, value);
  }

  // --- Reminders ---

  bool get remindersEnabled =>
      _prefs.getBool(SPKeys.remindersEnabled) ?? false;

  Future<void> setRemindersEnabled(bool value) async {
    await _prefs.setBool(SPKeys.remindersEnabled, value);
  }

  int get reminderStartHour =>
      _prefs.getInt(SPKeys.reminderStartHour) ?? Defaults.reminderStartHour;

  Future<void> setReminderStartHour(int hour) async {
    await _prefs.setInt(SPKeys.reminderStartHour, hour);
  }

  int get reminderEndHour =>
      _prefs.getInt(SPKeys.reminderEndHour) ?? Defaults.reminderEndHour;

  Future<void> setReminderEndHour(int hour) async {
    await _prefs.setInt(SPKeys.reminderEndHour, hour);
  }

  int get reminderIntervalMin =>
      _prefs.getInt(SPKeys.reminderIntervalMin) ??
      Defaults.reminderIntervalMin;

  Future<void> setReminderIntervalMin(int min) async {
    await _prefs.setInt(SPKeys.reminderIntervalMin, min);
  }

  // --- Effective hydration ---

  int get effectiveHydrationMl =>
      _prefs.getInt(SPKeys.effectiveHydrationMl) ?? 0;

  Future<void> setEffectiveHydrationMl(int ml) async {
    await _prefs.setInt(SPKeys.effectiveHydrationMl, ml);
  }

  // --- Selected beverage ---

  String get selectedBeverageId =>
      _prefs.getString(SPKeys.selectedBeverageId) ?? 'water';

  Future<void> setSelectedBeverageId(String id) async {
    await _prefs.setString(SPKeys.selectedBeverageId, id);
  }

  // --- Streak freeze ---

  int get streakFreezes => _prefs.getInt(SPKeys.streakFreezes) ?? 0;

  Future<void> setStreakFreezes(int count) async {
    await _prefs.setInt(SPKeys.streakFreezes, count);
  }

  /// Returns the ISO week number string "yyyy-Www" for tracking weekly resets.
  String get _currentWeekKey {
    final now = DateTime.now();
    final jan1 = DateTime(now.year, 1, 1);
    final weekNum = ((now.difference(jan1).inDays + jan1.weekday) / 7).ceil();
    return '${now.year}-W$weekNum';
  }

  /// Resets freezes to the weekly allowance if a new week has started.
  /// Returns the current freeze count after any reset.
  int refreshWeeklyFreezes({required bool isPremium}) {
    final lastWeek = _prefs.getString(SPKeys.lastFreezeResetWeek);
    final currentWeek = _currentWeekKey;
    if (lastWeek != currentWeek) {
      final allowance = isPremium ? 2 : 1;
      _prefs.setString(SPKeys.lastFreezeResetWeek, currentWeek);
      _prefs.setInt(SPKeys.streakFreezes, allowance);
      return allowance;
    }
    return streakFreezes;
  }

  // --- Hydration calculator ---

  int? get userWeightKg {
    final v = _prefs.getInt(SPKeys.userWeightKg);
    return v;
  }

  Future<void> setUserWeightKg(int kg) async {
    await _prefs.setInt(SPKeys.userWeightKg, kg);
  }

  int get activityLevel => _prefs.getInt(SPKeys.activityLevel) ?? 0;

  Future<void> setActivityLevel(int level) async {
    await _prefs.setInt(SPKeys.activityLevel, level);
  }

  // --- Accent color ---

  int get accentColorIndex => _prefs.getInt(SPKeys.accentColorIndex) ?? 0;

  Future<void> setAccentColorIndex(int index) async {
    await _prefs.setInt(SPKeys.accentColorIndex, index);
  }

  // --- Sound ---

  bool get soundEnabled => _prefs.getBool(SPKeys.soundEnabled) ?? true;

  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool(SPKeys.soundEnabled, value);
  }

  // --- Health Connect ---

  bool get healthConnectEnabled =>
      _prefs.getBool(SPKeys.healthConnectEnabled) ?? false;

  Future<void> setHealthConnectEnabled(bool value) async {
    await _prefs.setBool(SPKeys.healthConnectEnabled, value);
  }

  // --- Generic access ---

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  // --- Today entries (JSON list) ---

  String? get todayEntriesRaw => _prefs.getString(SPKeys.todayEntries);

  Future<void> setTodayEntries(String json) async {
    await _prefs.setString(SPKeys.todayEntries, json);
  }

  // --- Daily goal in ml ---

  /// Returns the goal in ml. Migrates from legacy format if needed.
  int get dailyGoalMl {
    final saved = _prefs.getInt(SPKeys.dailyGoalMl);
    if (saved != null) return saved;
    // Migrate from legacy: dailyGoal (glasses) * glassSizeMl
    return dailyGoal * glassSizeMl;
  }

  Future<void> setDailyGoalMl(int ml) async {
    await _prefs.setInt(SPKeys.dailyGoalMl, ml);
  }

  // --- Daily reset check ---

  /// Returns true if a reset was needed (i.e. it's a new day).
  bool needsDailyReset() {
    final last = lastResetDate;
    return last != AppDateUtils.todayKey();
  }
}
