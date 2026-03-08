import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../services/notification_service.dart';
import '../../services/health_service.dart';
import 'widgets/goal_picker.dart';
import 'widgets/reminder_config.dart';
import 'widgets/premium_card.dart';
import 'widgets/hydration_calculator.dart';
import 'widgets/accent_picker.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../main.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isPremium = ref.watch(premiumProvider);
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Daily goal in ml
          GoalPicker(
            label: 'Objetivo diario (ml)',
            value: settings.dailyGoalMl,
            min: 500,
            max: 5000,
            step: 250,
            onChanged: (v) {
              ref.read(settingsProvider.notifier).setDailyGoalMl(v);
              ref.read(waterProvider.notifier).setGoalMl(v);
              ref.read(achievementsProvider.notifier).unlockManual('customizer');
            },
          ),
          const SizedBox(height: 16),

          // Hydration calculator
          Builder(builder: (context) {
            final storage = ref.read(storageServiceProvider);
            return HydrationCalculator(
              savedWeightKg: storage.userWeightKg,
              savedActivityLevel: storage.activityLevel,
              onApplyGoal: (ml) {
                ref.read(settingsProvider.notifier).setDailyGoalMl(ml);
                ref.read(waterProvider.notifier).setGoalMl(ml);
                ref.read(achievementsProvider.notifier).unlockManual('customizer');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Objetivo actualizado a $ml ml'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 24),

          // Dark mode
          Card(
            child: SwitchListTile(
              title: const Text(
                'Modo oscuro',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Sound toggle
          Builder(builder: (context) {
            final storage = ref.read(storageServiceProvider);
            final soundOn = storage.soundEnabled;
            return Card(
              child: SwitchListTile(
                title: const Text(
                  'Sonido al beber',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                secondary: Icon(
                  soundOn ? Icons.volume_up : Icons.volume_off,
                  color: Theme.of(context).colorScheme.primary,
                ),
                value: soundOn,
                onChanged: (v) {
                  storage.setSoundEnabled(v);
                  (context as Element).markNeedsBuild();
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }),
          const SizedBox(height: 16),

          // Accent color picker
          AccentPicker(
            selectedIndex: ref.watch(accentProvider),
            isPremium: isPremium,
            onChanged: (index) {
              ref.read(accentProvider.notifier).setIndex(index);
            },
          ),
          const SizedBox(height: 24),

          // Reminders
          ReminderConfig(
            enabled: settings.remindersEnabled,
            intervalMin: settings.reminderIntervalMin,
            onEnabledChanged: (v) async {
              await ref
                  .read(settingsProvider.notifier)
                  .setRemindersEnabled(v);
              if (v) {
                await NotificationService.scheduleReminders(
                  startHour: settings.reminderStartHour,
                  endHour: settings.reminderEndHour,
                  intervalMin: settings.reminderIntervalMin,
                );
              } else {
                await NotificationService.cancelAll();
              }
            },
            onIntervalChanged: (v) async {
              await ref
                  .read(settingsProvider.notifier)
                  .setReminderIntervalMin(v);
              if (settings.remindersEnabled) {
                await NotificationService.scheduleReminders(
                  startHour: settings.reminderStartHour,
                  endHour: settings.reminderEndHour,
                  intervalMin: v,
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Health Connect
          Builder(builder: (context) {
            final storage = ref.read(storageServiceProvider);
            final healthOn = storage.healthConnectEnabled;
            return Card(
              child: SwitchListTile(
                title: const Text(
                  'Health Connect',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Sincronizar con Google Fit'),
                secondary: Icon(
                  Icons.favorite,
                  color: healthOn ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                value: healthOn,
                onChanged: (v) async {
                  if (v) {
                    final granted = await HealthService.requestPermissions();
                    if (!granted) return;
                  }
                  await storage.setHealthConnectEnabled(v);
                  (context as Element).markNeedsBuild();
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }),
          const SizedBox(height: 24),

          // Premium
          PremiumCard(isPremium: isPremium),

          // Privacy policy link
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: Icon(Icons.privacy_tip, color: Theme.of(context).colorScheme.primary),
              title: const Text('Politica de privacidad'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Politica de privacidad'),
                    content: const Text(
                      'AguaHoy no recopila ni envia datos personales. '
                      'Toda la informacion se almacena localmente en tu dispositivo. '
                      'Los anuncios son gestionados por Google AdMob, '
                      'que puede recopilar datos anonimos segun su propia politica.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Ad banner
          if (!isPremium) ...[
            const SizedBox(height: 24),
            const AdBannerWidget(),
          ],
        ],
      ),
    );
  }
}
