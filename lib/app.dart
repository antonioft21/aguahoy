import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'main.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/stats/stats_screen.dart';

enum _AppPhase { splash, onboarding, home }

final _appPhaseProvider = StateProvider<_AppPhase>((ref) => _AppPhase.splash);

final _onboardingDoneProvider = StateProvider<bool>((ref) {
  final storage = ref.read(storageServiceProvider);
  return storage.getBool(SPKeys.onboardingComplete) ?? false;
});

class AguaHoyApp extends ConsumerWidget {
  const AguaHoyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final accentIndex = ref.watch(accentProvider);
    final phase = ref.watch(_appPhaseProvider);
    final onboardingDone = ref.watch(_onboardingDoneProvider);
    final accent = AccentColors.colors[accentIndex.clamp(0, AccentColors.colors.length - 1)];

    return MaterialApp(
      title: 'AguaHoy',
      debugShowCheckedModeBanner: false,
      theme: AguaTheme.lightTheme(accent),
      darkTheme: AguaTheme.darkTheme(accent),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: _buildHome(ref, phase, onboardingDone),
      routes: {
        '/history': (_) => const HistoryScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/achievements': (_) => const AchievementsScreen(),
        '/stats': (_) => const StatsScreen(),
      },
    );
  }

  Widget _buildHome(WidgetRef ref, _AppPhase phase, bool onboardingDone) {
    switch (phase) {
      case _AppPhase.splash:
        return SplashScreen(
          onComplete: () {
            ref.read(_appPhaseProvider.notifier).state =
                onboardingDone ? _AppPhase.home : _AppPhase.onboarding;
          },
        );
      case _AppPhase.onboarding:
        return OnboardingScreen(
          onComplete: () {
            final storage = ref.read(storageServiceProvider);
            storage.setBool(SPKeys.onboardingComplete, true);
            ref.read(_onboardingDoneProvider.notifier).state = true;
            ref.read(_appPhaseProvider.notifier).state = _AppPhase.home;
          },
        );
      case _AppPhase.home:
        return const HomeScreen();
    }
  }
}
