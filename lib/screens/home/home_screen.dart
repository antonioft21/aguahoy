import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/water_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/rank_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../models/achievement.dart';
import '../../core/theme.dart';
import '../../widgets/ad_banner_widget.dart';
import 'widgets/progress_circle.dart';
import 'widgets/glass_icons_row.dart';
import 'widgets/water_button.dart';
import 'widgets/ml_label.dart';
import 'widgets/beverage_selector.dart';
import 'widgets/weekly_challenge_card.dart';
import 'widgets/goal_suggestion_card.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/history_provider.dart';
import '../../main.dart';
import '../../core/constants.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _showCelebration = false;
  bool _previousGoalMet = false;
  Achievement? _unlockedAchievement;
  bool _showAchievement = false;
  bool _goalSuggestionDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _previousGoalMet = ref.read(waterProvider).goalMet;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(waterProvider.notifier).reconcileFromWidget();
    }
  }

  void _onAddGlass() async {
    HapticFeedback.mediumImpact();
    await ref.read(waterProvider.notifier).addGlass();

    // Check if goal was just met
    final water = ref.read(waterProvider);
    if (water.goalMet && !_previousGoalMet) {
      _celebrate();
    }
    _previousGoalMet = water.goalMet;

    // Check achievements
    final newAchievements =
        await ref.read(achievementsProvider.notifier).checkAll();
    if (newAchievements.isNotEmpty && mounted) {
      final first = achievementMap[newAchievements.first];
      if (first != null) {
        _showAchievementOverlay(first);
      }
    }
  }

  void _celebrate() {
    setState(() => _showCelebration = true);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCelebration = false);
    });
  }

  void _showAchievementOverlay(Achievement achievement) {
    HapticFeedback.heavyImpact();
    setState(() {
      _unlockedAchievement = achievement;
      _showAchievement = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showAchievement = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final water = ref.watch(waterProvider);
    final isPremium = ref.watch(premiumProvider);

    // Keep tracking goal state for celebration detection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previousGoalMet = water.goalMet;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AguaHoy',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {
              ref.read(achievementsProvider.notifier).unlockManual('explorer');
              Navigator.pushNamed(context, '/achievements');
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              ref.read(achievementsProvider.notifier).unlockManual('explorer');
              Navigator.pushNamed(context, '/history');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        ProgressCircle(
                          progress: water.progress,
                          goalMet: water.goalMet,
                        ),
                        const SizedBox(height: 20),
                        MlLabel(
                          currentMl: water.effectiveHydrationMl,
                          goalMl: water.goalMl,
                        ),
                        const SizedBox(height: 8),
                        // Rank badge
                        ref.watch(rankProvider).when(
                          data: (rank) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(rank.icon, size: 16, color: AguaTheme.primaryBlue),
                              const SizedBox(width: 6),
                              Text(
                                rank.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AguaTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 16),
                        GlassIconsRow(
                          filled: water.currentCount,
                          total: water.dailyGoal,
                        ),
                        const SizedBox(height: 20),
                        BeverageSelector(
                          selectedId: water.selectedBeverageId,
                          onSelected: (id) {
                            ref.read(waterProvider.notifier).selectBeverage(id);
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            WaterButton(
                              icon: Icons.remove,
                              onPressed: water.currentCount > 0
                                  ? () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(waterProvider.notifier)
                                          .removeGlass();
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 32),
                            WaterButton(
                              icon: Icons.add,
                              isPrimary: true,
                              onPressed: _onAddGlass,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${water.glassSizeMl} ml por vaso',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        // Goal suggestion (if streak >= 7)
                        if (!_goalSuggestionDismissed)
                          ref.watch(streakProvider).when(
                            data: (streak) {
                              if (streak < 7) return const SizedBox.shrink();
                              // Check if already dismissed recently
                              final storage = ref.read(storageServiceProvider);
                              final dismissed = storage.getBool(SPKeys.goalSuggestionDismissedAt);
                              if (dismissed == true) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GoalSuggestionCard(
                                  currentGoal: water.dailyGoal,
                                  streak: streak,
                                  onAccept: () {
                                    final newGoal = water.dailyGoal + 1;
                                    ref.read(waterProvider.notifier).setGoal(newGoal);
                                    storage.setBool(SPKeys.goalSuggestionDismissedAt, true);
                                    setState(() => _goalSuggestionDismissed = true);
                                  },
                                  onDismiss: () {
                                    storage.setBool(SPKeys.goalSuggestionDismissedAt, true);
                                    setState(() => _goalSuggestionDismissed = true);
                                  },
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        // Weekly challenge
                        ref.watch(challengeProvider).when(
                          data: (state) =>
                              WeeklyChallengeCard(challengeState: state),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                if (!isPremium) const AdBannerWidget(),
              ],
            ),
            // Celebration overlay
            if (_showCelebration)
              AnimatedOpacity(
                opacity: _showCelebration ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black26,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color ??
                              Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🎉',
                              style: TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Objetivo cumplido!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sigue asi, campeon!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Achievement unlock overlay
            if (_showAchievement && _unlockedAchievement != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: -1.0, end: 0.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, offset, child) {
                      return Transform.translate(
                        offset: Offset(0, offset * 100),
                        child: child,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Icon(
                              _unlockedAchievement!.icon,
                              color: Colors.amber,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Logro desbloqueado!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.amber[700],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _unlockedAchievement!.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
