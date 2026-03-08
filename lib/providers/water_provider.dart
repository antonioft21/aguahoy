import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../core/date_utils.dart';
import '../models/day_record.dart';
import '../models/drink_entry.dart';
import '../models/beverage.dart';
import '../services/history_service.dart';
import '../services/widget_service.dart';
import '../services/health_service.dart';

/// The core water tracking state — entry-based.
class WaterState {
  final List<DrinkEntry> entries;
  final int goalMl;
  final String selectedBeverageId;

  const WaterState({
    required this.entries,
    required this.goalMl,
    this.selectedBeverageId = 'water',
  });

  /// Total volume in ml (raw, before hydration ratio).
  int get totalVolumeMl =>
      entries.fold<int>(0, (s, e) => s + e.volumeMl);

  /// Effective hydration ml (after hydration ratio).
  int get effectiveHydrationMl =>
      entries.fold<int>(0, (s, e) => s + e.effectiveMl);

  /// Number of entries (replaces old currentCount).
  int get currentCount => entries.length;

  double get progress =>
      goalMl > 0 ? (effectiveHydrationMl / goalMl).clamp(0.0, 1.0) : 0.0;

  bool get goalMet => effectiveHydrationMl >= goalMl;

  Beverage get selectedBeverage =>
      beverageMap[selectedBeverageId] ?? beverages[0];

  /// Breakdown by beverage: beverageId -> effective ml.
  Map<String, int> get mlByBeverage {
    final map = <String, int>{};
    for (final e in entries) {
      map[e.beverageId] = (map[e.beverageId] ?? 0) + e.effectiveMl;
    }
    return map;
  }

  WaterState copyWith({
    List<DrinkEntry>? entries,
    int? goalMl,
    String? selectedBeverageId,
  }) {
    return WaterState(
      entries: entries ?? this.entries,
      goalMl: goalMl ?? this.goalMl,
      selectedBeverageId: selectedBeverageId ?? this.selectedBeverageId,
    );
  }
}

class WaterNotifier extends StateNotifier<WaterState> {
  final Ref _ref;
  final HistoryService _historyService = HistoryService();

  WaterNotifier(this._ref)
      : super(const WaterState(
          entries: [],
          goalMl: 2000,
        )) {
    _init();
  }

  void _init() {
    final storage = _ref.read(storageServiceProvider);

    // Check daily reset
    if (storage.needsDailyReset()) {
      _performDailyReset(storage);
    }

    final goalMl = storage.dailyGoalMl;
    final selectedBev = storage.selectedBeverageId;

    // Load entries from JSON
    var entries = _loadEntries(storage);

    // Migration: if no entries but legacy count > 0, create synthetic entries
    if (entries.isEmpty && storage.currentCount > 0) {
      final legacyCount = storage.currentCount;
      final legacyGlassSize = storage.glassSizeMl;
      final legacyBevId = storage.selectedBeverageId;
      final bev = beverageMap[legacyBevId] ?? beverages[0];
      entries = List.generate(legacyCount, (i) {
        final ts = DateTime.now().subtract(Duration(minutes: legacyCount - i));
        return DrinkEntry(
          id: ts.microsecondsSinceEpoch.toString(),
          beverageId: legacyBevId,
          volumeMl: legacyGlassSize,
          effectiveMl: bev.effectiveMl(legacyGlassSize),
          timestamp: ts,
        );
      });
      _saveEntries(storage, entries);
    }

    state = WaterState(
      entries: entries,
      goalMl: goalMl,
      selectedBeverageId: selectedBev,
    );

    // Write legacy keys for widget compatibility
    _syncLegacyKeys(storage);

    // Ensure today exists in history
    _saveTodayToHistory();
  }

  List<DrinkEntry> _loadEntries(dynamic storage) {
    final raw = storage.todayEntriesRaw;
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => DrinkEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveEntries(dynamic storage, List<DrinkEntry> entries) async {
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await storage.setTodayEntries(json);
  }

  void _performDailyReset(dynamic storage) {
    final lastDate = storage.lastResetDate;
    final previousCount = storage.currentCount;

    // Save previous day to history (if there was data).
    if (lastDate != null && previousCount > 0) {
      // Try to load entries for accurate ml, fall back to legacy
      final entries = _loadEntries(storage);
      final totalMl = entries.isNotEmpty
          ? entries.fold<int>(0, (s, e) => s + e.effectiveMl)
          : previousCount * storage.glassSizeMl;
      final goalMl = storage.dailyGoalMl;

      _historyService
          .saveDay(DayRecord(
            dateKey: lastDate,
            glasses: previousCount,
            goalGlasses: storage.dailyGoal,
            glassSizeMl: storage.glassSizeMl,
            totalMlDirect: totalMl,
            goalMlDirect: goalMl,
          ))
          .catchError((_) {});
    }

    // Reset
    storage.setCurrentCount(0);
    storage.setEffectiveHydrationMl(0);
    storage.setTodayEntries('[]');
    storage.setLastResetDate(AppDateUtils.todayKey());

    _trySyncWidget(
      currentCount: 0,
      dailyGoal: storage.dailyGoal,
      glassSizeMl: storage.glassSizeMl,
    );
  }

  Future<void> addDrink(int volumeMl) async {
    final storage = _ref.read(storageServiceProvider);
    final bev = state.selectedBeverage;
    final now = DateTime.now();
    final entry = DrinkEntry(
      id: now.microsecondsSinceEpoch.toString(),
      beverageId: bev.id,
      volumeMl: volumeMl,
      effectiveMl: bev.effectiveMl(volumeMl),
      timestamp: now,
    );

    final newEntries = [...state.entries, entry];
    state = state.copyWith(entries: newEntries);

    await _saveEntries(storage, newEntries);
    _syncLegacyKeys(storage);
    await _syncWidget();
    _saveTodayToHistory();
    _trySyncHealth(volumeMl);
  }

  Future<void> undoLast() async {
    if (state.entries.isEmpty) return;
    final storage = _ref.read(storageServiceProvider);
    final newEntries = [...state.entries]..removeLast();
    state = state.copyWith(entries: newEntries);

    await _saveEntries(storage, newEntries);
    _syncLegacyKeys(storage);
    await _syncWidget();
    _saveTodayToHistory();
  }

  Future<void> selectBeverage(String beverageId) async {
    final storage = _ref.read(storageServiceProvider);
    state = state.copyWith(selectedBeverageId: beverageId);
    await storage.setSelectedBeverageId(beverageId);
  }

  Future<void> setGoalMl(int ml) async {
    final storage = _ref.read(storageServiceProvider);
    state = state.copyWith(goalMl: ml);
    await storage.setDailyGoalMl(ml);
    // Also update legacy keys for widget
    final legacyGlassSize = storage.glassSizeMl;
    final legacyGoal = (ml / legacyGlassSize).ceil();
    await storage.setDailyGoal(legacyGoal);
    await _syncWidget();
    _saveTodayToHistory();
  }

  /// Persists today's progress to Hive so history is always up-to-date.
  void _saveTodayToHistory() {
    final storage = _ref.read(storageServiceProvider);
    _historyService
        .saveDay(DayRecord(
          dateKey: AppDateUtils.todayKey(),
          glasses: state.currentCount,
          goalGlasses: storage.dailyGoal,
          glassSizeMl: storage.glassSizeMl,
          totalMlDirect: state.effectiveHydrationMl,
          goalMlDirect: state.goalMl,
        ))
        .catchError((_) {});
  }

  /// Keep legacy SharedPreferences keys in sync for Android widget.
  void _syncLegacyKeys(dynamic storage) {
    storage.setCurrentCount(state.currentCount);
    storage.setEffectiveHydrationMl(state.effectiveHydrationMl);
  }

  /// Called on app resume to adopt widget taps.
  Future<void> reconcileFromWidget() async {
    final storage = _ref.read(storageServiceProvider);

    if (storage.needsDailyReset()) {
      _performDailyReset(storage);
      state = WaterState(
        entries: [],
        goalMl: storage.dailyGoalMl,
        selectedBeverageId: state.selectedBeverageId,
      );
      return;
    }

    // Widget taps always count as water (250ml, ratio 1.0)
    final widgetCount = storage.currentCount;
    if (widgetCount > state.currentCount) {
      final diff = widgetCount - state.currentCount;
      final glassSizeMl = storage.glassSizeMl;
      final newEntries = [...state.entries];
      for (var i = 0; i < diff; i++) {
        final now = DateTime.now().subtract(Duration(seconds: diff - i));
        newEntries.add(DrinkEntry(
          id: now.microsecondsSinceEpoch.toString(),
          beverageId: 'water',
          volumeMl: glassSizeMl,
          effectiveMl: glassSizeMl, // water ratio = 1.0
          timestamp: now,
        ));
      }
      state = state.copyWith(entries: newEntries);
      await _saveEntries(storage, newEntries);
      _syncLegacyKeys(storage);
      _saveTodayToHistory();
    }
  }

  Future<void> _syncWidget() async {
    final storage = _ref.read(storageServiceProvider);
    await _trySyncWidget(
      currentCount: state.currentCount,
      dailyGoal: storage.dailyGoal,
      glassSizeMl: storage.glassSizeMl,
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
    } catch (_) {}
  }

  void _trySyncHealth(int ml) {
    try {
      final storage = _ref.read(storageServiceProvider);
      if (storage.healthConnectEnabled) {
        HealthService.writeWaterIntake(ml);
      }
    } catch (_) {}
  }
}

final waterProvider = StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  return WaterNotifier(ref);
});
