import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'history_provider.dart';

class RankInfo {
  final String title;
  final IconData icon;

  const RankInfo({required this.title, required this.icon});
}

const _ranks = [
  RankInfo(title: 'Gota Principiante', icon: Icons.water_drop_outlined),
  RankInfo(title: 'Ola Constante', icon: Icons.water),
  RankInfo(title: 'Rio Imparable', icon: Icons.waves),
  RankInfo(title: 'Oceano Legendario', icon: Icons.tsunami),
];

RankInfo getRankForStreak(int streak) {
  if (streak >= 30) return _ranks[3];
  if (streak >= 14) return _ranks[2];
  if (streak >= 7) return _ranks[1];
  return _ranks[0];
}

/// Provides the current rank based on streak.
final rankProvider = FutureProvider<RankInfo>((ref) async {
  final streak = await ref.watch(streakProvider.future);
  return getRankForStreak(streak);
});
