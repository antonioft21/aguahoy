import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class SettingsState {
  final int dailyGoal;
  final int glassSizeMl;
  final bool remindersEnabled;
  final int reminderStartHour;
  final int reminderEndHour;
  final int reminderIntervalMin;

  const SettingsState({
    required this.dailyGoal,
    required this.glassSizeMl,
    required this.remindersEnabled,
    required this.reminderStartHour,
    required this.reminderEndHour,
    required this.reminderIntervalMin,
  });

  SettingsState copyWith({
    int? dailyGoal,
    int? glassSizeMl,
    bool? remindersEnabled,
    int? reminderStartHour,
    int? reminderEndHour,
    int? reminderIntervalMin,
  }) {
    return SettingsState(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      glassSizeMl: glassSizeMl ?? this.glassSizeMl,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderStartHour: reminderStartHour ?? this.reminderStartHour,
      reminderEndHour: reminderEndHour ?? this.reminderEndHour,
      reminderIntervalMin: reminderIntervalMin ?? this.reminderIntervalMin,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref)
      : super(const SettingsState(
          dailyGoal: 8,
          glassSizeMl: 250,
          remindersEnabled: false,
          reminderStartHour: 8,
          reminderEndHour: 22,
          reminderIntervalMin: 60,
        )) {
    _init();
  }

  void _init() {
    final storage = _ref.read(storageServiceProvider);
    state = SettingsState(
      dailyGoal: storage.dailyGoal,
      glassSizeMl: storage.glassSizeMl,
      remindersEnabled: storage.remindersEnabled,
      reminderStartHour: storage.reminderStartHour,
      reminderEndHour: storage.reminderEndHour,
      reminderIntervalMin: storage.reminderIntervalMin,
    );
  }

  Future<void> setDailyGoal(int goal) async {
    final storage = _ref.read(storageServiceProvider);
    state = state.copyWith(dailyGoal: goal);
    await storage.setDailyGoal(goal);
  }

  Future<void> setGlassSizeMl(int ml) async {
    final storage = _ref.read(storageServiceProvider);
    state = state.copyWith(glassSizeMl: ml);
    await storage.setGlassSizeMl(ml);
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    final storage = _ref.read(storageServiceProvider);
    state = state.copyWith(remindersEnabled: enabled);
    await storage.setRemindersEnabled(enabled);
  }

  Future<void> setReminderStartHour(int hour) async {
    final storage = _ref.read(storageServiceProvider);
    state = state.copyWith(reminderStartHour: hour);
    await storage.setReminderStartHour(hour);
  }

  Future<void> setReminderEndHour(int hour) async {
    final storage = _ref.read(storageServiceProvider);
    state = state.copyWith(reminderEndHour: hour);
    await storage.setReminderEndHour(hour);
  }

  Future<void> setReminderIntervalMin(int min) async {
    final storage = _ref.read(storageServiceProvider);
    state = state.copyWith(reminderIntervalMin: min);
    await storage.setReminderIntervalMin(min);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
