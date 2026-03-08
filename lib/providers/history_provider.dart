import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/day_record.dart';
import '../services/history_service.dart';
import 'water_provider.dart';
import 'premium_provider.dart';

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

/// Fetches recent history records. Re-runs whenever water state changes.
final recentHistoryProvider =
    FutureProvider.family<List<DayRecord>, int>((ref, days) async {
  ref.watch(waterProvider);
  final service = ref.read(historyServiceProvider);
  return service.getRecentDays(days);
});

/// Current streak (accounts for streak freezes). Re-runs whenever water state changes.
final streakProvider = FutureProvider<int>((ref) async {
  ref.watch(waterProvider);
  final storage = ref.read(storageServiceProvider);
  final isPremium = ref.read(premiumProvider);
  final freezes = storage.refreshWeeklyFreezes(isPremium: isPremium);
  final service = ref.read(historyServiceProvider);
  return service.calculateStreak(freezesAvailable: freezes);
});

/// Weekly average in ml. Re-runs whenever water state changes.
final weeklyAverageProvider = FutureProvider<double>((ref) async {
  ref.watch(waterProvider);
  final service = ref.read(historyServiceProvider);
  return service.averageMl(7);
});
