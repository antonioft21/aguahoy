import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/day_record.dart';
import 'history_provider.dart';
import 'water_provider.dart';

class AdvancedStats {
  final int totalLiters;
  final int totalGlasses;
  final int daysTracked;
  final int daysGoalMet;
  final DayRecord? bestDay;
  final int avgMl30d;
  final Map<int, int> monthlyAvgMl; // month (1-12) -> avg ml

  const AdvancedStats({
    required this.totalLiters,
    required this.totalGlasses,
    required this.daysTracked,
    required this.daysGoalMet,
    required this.bestDay,
    required this.avgMl30d,
    required this.monthlyAvgMl,
  });

  double get goalMetPercent =>
      daysTracked > 0 ? (daysGoalMet / daysTracked * 100) : 0;
}

final advancedStatsProvider = FutureProvider<AdvancedStats>((ref) async {
  ref.watch(waterProvider);
  final service = ref.read(historyServiceProvider);
  final allRecords = await service.getAllRecords();

  if (allRecords.isEmpty) {
    return const AdvancedStats(
      totalLiters: 0,
      totalGlasses: 0,
      daysTracked: 0,
      daysGoalMet: 0,
      bestDay: null,
      avgMl30d: 0,
      monthlyAvgMl: {},
    );
  }

  final totalGlasses = allRecords.fold<int>(0, (s, r) => s + r.glasses);
  final totalMl = allRecords.fold<int>(0, (s, r) => s + r.totalMl);
  final daysGoalMet = allRecords.where((r) => r.goalMet).length;

  DayRecord? bestDay;
  for (final r in allRecords) {
    if (bestDay == null || r.totalMl > bestDay.totalMl) {
      bestDay = r;
    }
  }

  // 30-day average in ml
  final recent30 = await service.getRecentDays(30);
  final avgMl30d = recent30.isEmpty
      ? 0
      : (recent30.fold<int>(0, (s, r) => s + r.totalMl) / recent30.length).round();

  // Monthly averages in ml (current year)
  final now = DateTime.now();
  final monthlyAvgMl = <int, int>{};
  for (var m = 1; m <= 12; m++) {
    final monthRecords = allRecords.where((r) {
      final d = DateTime.tryParse(r.dateKey);
      return d != null && d.year == now.year && d.month == m;
    }).toList();
    if (monthRecords.isNotEmpty) {
      monthlyAvgMl[m] = (monthRecords.fold<int>(0, (s, r) => s + r.totalMl) /
          monthRecords.length).round();
    }
  }

  return AdvancedStats(
    totalLiters: (totalMl / 1000).round(),
    totalGlasses: totalGlasses,
    daysTracked: allRecords.length,
    daysGoalMet: daysGoalMet,
    bestDay: bestDay,
    avgMl30d: avgMl30d,
    monthlyAvgMl: monthlyAvgMl,
  );
});
