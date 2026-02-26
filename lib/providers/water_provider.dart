import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../core/date_utils.dart';
import '../models/day_record.dart';
import '../models/beverage.dart';
import '../services/history_service.dart';
import '../services/widget_service.dart';

/// The core water tracking state.
class WaterState {
  final int currentCount;
  final int dailyGoal;
  final int glassSizeMl;
  final int effectiveHydrationMl; // real hydration accounting for beverage ratios
  final String selectedBeverageId;

  const WaterState({
    required this.currentCount,
    required this.dailyGoal,
    required this.glassSizeMl,
    this.effectiveHydrationMl = 0,
    this.selectedBeverageId = 'water',
  });

  int get currentMl => currentCount * glassSizeMl;
  int get goalMl => dailyGoal * glassSizeMl;
  double get progress =>
      goalMl > 0 ? (effectiveHydrationMl / goalMl).clamp(0.0, 1.0) : 0.0;
  bool get goalMet => effectiveHydrationMl >= goalMl;
  Beverage get selectedBeverage => beverageMap[selectedBeverageId] ?? beverages[0];

  WaterState copyWith({
    int? currentCount,
    int? dailyGoal,
    int? glassSizeMl,
    int? effectiveHydrationMl,
    String? selectedBeverageId,
  }) {
    return WaterState(
      currentCount: currentCount ?? this.currentCount,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      glassSizeMl: glassSizeMl ?? this.glassSizeMl,
      effectiveHydrationMl: effectiveHydrationMl ?? this.effectiveHydrationMl,
      selectedBeverageId: selectedBeverageId ?? this.selectedBeverageId,
    );
  }
}

class WaterNotifier extends StateNotifier<WaterState> {
  final Ref _ref;
  final HistoryService _historyService = HistoryService();

  WaterNotifier(this._ref)
      : super(const WaterState(
          currentCount: 0,
          dailyGoal: 8,
          glassSizeMl: 250,
        )) {
    _init();
  }

  void _init() {
    final storage = _ref.read(storageServiceProvider);

    // Check daily reset
    if (storage.needsDailyReset()) {
      _performDailyReset(storage);
    }

    final count = storage.currentCount;
    final glassSizeMl = storage.glassSizeMl;
    var effectiveHydration = storage.effectiveHydrationMl;

    // Backward compatibility: if there are glasses but no effective hydration,
    // assume all past glasses were water (ratio 1.0).
    if (effectiveHydration == 0 && count > 0) {
      effectiveHydration = count * glassSizeMl;
      storage.setEffectiveHydrationMl(effectiveHydration);
    }

    state = WaterState(
      currentCount: count,
      dailyGoal: storage.dailyGoal,
      glassSizeMl: glassSizeMl,
      effectiveHydrationMl: effectiveHydration,
      selectedBeverageId: storage.selectedBeverageId,
    );

    // Ensure today exists in history from the start
    _saveTodayToHistory();
  }

  void _performDailyReset(dynamic storage) {
    final lastDate = storage.lastResetDate;
    final previousCount = storage.currentCount;

    // Save previous day to history (if there was data).
    // Fire-and-forget — errors are swallowed (e.g., Hive not initialized in tests).
    if (lastDate != null && previousCount > 0) {
      _historyService
          .saveDay(DayRecord(
            dateKey: lastDate,
            glasses: previousCount,
            goalGlasses: storage.dailyGoal,
            glassSizeMl: storage.glassSizeMl,
          ))
          .catchError((_) {});
    }

    // Reset counter
    storage.setCurrentCount(0);
    storage.setEffectiveHydrationMl(0);
    storage.setLastResetDate(AppDateUtils.todayKey());

    // Sync widget with reset (may fail in test environment)
    _trySyncWidget(
      currentCount: 0,
      dailyGoal: storage.dailyGoal,
      glassSizeMl: storage.glassSizeMl,
    );
  }

  Future<void> addGlass() async {
    final storage = _ref.read(storageServiceProvider);
    final newCount = state.currentCount + 1;
    final hydrationDelta = state.selectedBeverage.effectiveMl(state.glassSizeMl);
    final newHydration = state.effectiveHydrationMl + hydrationDelta;
    state = state.copyWith(
      currentCount: newCount,
      effectiveHydrationMl: newHydration,
    );
    await storage.setCurrentCount(newCount);
    await storage.setEffectiveHydrationMl(newHydration);
    await _syncWidget();
    _saveTodayToHistory();
  }

  Future<void> removeGlass() async {
    if (state.currentCount <= 0) return;
    final storage = _ref.read(storageServiceProvider);
    final newCount = state.currentCount - 1;
    // Remove using current beverage ratio (clamped to 0)
    final hydrationDelta = state.selectedBeverage.effectiveMl(state.glassSizeMl);
    final newHydration = (state.effectiveHydrationMl - hydrationDelta).clamp(0, 999999);
    state = state.copyWith(
      currentCount: newCount,
      effectiveHydrationMl: newHydration,
    );
    await storage.setCurrentCount(newCount);
    await storage.setEffectiveHydrationMl(newHydration);
    await _syncWidget();
    _saveTodayToHistory();
  }

  Future<void> selectBeverage(String beverageId) async {
    final storage = _ref.read(storageServiceProvider);
    state = state.copyWith(selectedBeverageId: beverageId);
    await storage.setSelectedBeverageId(beverageId);
  }

  /// Persists today's progress to Hive so history is always up-to-date.
  void _saveTodayToHistory() {
    _historyService
        .saveDay(DayRecord(
          dateKey: AppDateUtils.todayKey(),
          glasses: state.currentCount,
          goalGlasses: state.dailyGoal,
          glassSizeMl: state.glassSizeMl,
        ))
        .catchError((_) {});
  }

  Future<void> setGoal(int goal) async {
    final storage = _ref.read(storageServiceProvider);
    state = state.copyWith(dailyGoal: goal);
    await storage.setDailyGoal(goal);
    await _syncWidget();
  }

  Future<void> setGlassSize(int ml) async {
    final storage = _ref.read(storageServiceProvider);
    state = state.copyWith(glassSizeMl: ml);
    await storage.setGlassSizeMl(ml);
    await _syncWidget();
  }

  /// Called on app resume to adopt widget taps.
  Future<void> reconcileFromWidget() async {
    final storage = _ref.read(storageServiceProvider);

    // Check for daily reset first
    if (storage.needsDailyReset()) {
      _performDailyReset(storage);
      state = WaterState(
        currentCount: 0,
        dailyGoal: storage.dailyGoal,
        glassSizeMl: storage.glassSizeMl,
        effectiveHydrationMl: 0,
        selectedBeverageId: state.selectedBeverageId,
      );
      return;
    }

    // Read what the widget wrote to SharedPreferences
    // Widget taps always count as water (ratio 1.0)
    final widgetCount = storage.currentCount;
    if (widgetCount != state.currentCount) {
      final diff = widgetCount - state.currentCount;
      final newHydration = state.effectiveHydrationMl + (diff * state.glassSizeMl);
      state = state.copyWith(
        currentCount: widgetCount,
        effectiveHydrationMl: newHydration.clamp(0, 999999),
      );
      await storage.setEffectiveHydrationMl(state.effectiveHydrationMl);
    }
  }

  Future<void> _syncWidget() async {
    await _trySyncWidget(
      currentCount: state.currentCount,
      dailyGoal: state.dailyGoal,
      glassSizeMl: state.glassSizeMl,
    );
  }

  Future<void> _trySyncWidget({
    required int currentCount,
    required int dailyGoal,
    required int glassSizeMl,
  }) async {
    try {
      await WidgetService.syncToWidget(
        currentCount: currentCount,
        dailyGoal: dailyGoal,
        glassSizeMl: glassSizeMl,
      );
    } catch (_) {
      // Platform channel not available (e.g., in tests)
    }
  }
}

final waterProvider = StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  return WaterNotifier(ref);
});
