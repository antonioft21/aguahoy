import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge.dart';
import '../models/day_record.dart';
import 'history_provider.dart';
import 'water_provider.dart';

class ChallengeState {
  final Challenge challenge;
  final int currentValue;
  final bool completed;

  const ChallengeState({
    required this.challenge,
    required this.currentValue,
    required this.completed,
  });

  double get progress =>
      challenge.targetValue > 0
          ? (currentValue / challenge.targetValue).clamp(0.0, 1.0)
          : 0.0;
}

/// Picks this week's challenge based on ISO week number.
Challenge _weeklyChallenge() {
  final now = DateTime.now();
  final jan1 = DateTime(now.year, 1, 1);
  final weekNum = ((now.difference(jan1).inDays + jan1.weekday) / 7).ceil();
  return weeklyChallenges[weekNum % weeklyChallenges.length];
}

/// Returns day records for the current ISO week (Mon-Sun).
List<DayRecord> _thisWeekRecords(List<DayRecord> allRecords) {
  final now = DateTime.now();
  // Monday of this week
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final mondayDate = DateTime(monday.year, monday.month, monday.day);

  return allRecords.where((r) {
    final d = DateTime.tryParse(r.dateKey);
    if (d == null) return false;
    return !d.isBefore(mondayDate) && d.difference(mondayDate).inDays < 7;
  }).toList();
}

int _evaluateChallenge(Challenge challenge, List<DayRecord> weekRecords) {
  switch (challenge.id) {
    case 'total_glasses_50':
    case 'total_glasses_70':
    case 'total_glasses_40':
      return weekRecords.fold<int>(0, (s, r) => s + r.glasses);
    case 'goal_5_days':
    case 'goal_7_days':
      return weekRecords.where((r) => r.goalMet).length;
    case 'goal_3_days':
      // Find max consecutive days meeting goal within the week
      var maxConsecutive = 0;
      var current = 0;
      // Sort by date
      final sorted = [...weekRecords]
        ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
      for (final r in sorted) {
        if (r.goalMet) {
          current++;
          if (current > maxConsecutive) maxConsecutive = current;
        } else {
          current = 0;
        }
      }
      return maxConsecutive;
    default:
      return 0;
  }
}

final challengeProvider = FutureProvider<ChallengeState>((ref) async {
  ref.watch(waterProvider); // re-evaluate on water changes
  final challenge = _weeklyChallenge();
  final service = ref.read(historyServiceProvider);
  final allRecords = await service.getRecentDays(7);
  final weekRecords = _thisWeekRecords(allRecords);
  final value = _evaluateChallenge(challenge, weekRecords);
  return ChallengeState(
    challenge: challenge,
    currentValue: value,
    completed: value >= challenge.targetValue,
  );
});
