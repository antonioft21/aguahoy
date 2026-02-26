import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../services/notification_service.dart';
import 'widgets/goal_picker.dart';
import 'widgets/reminder_config.dart';
import 'widgets/premium_card.dart';
import 'widgets/hydration_calculator.dart';
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
          // Daily goal
          GoalPicker(
            label: 'Objetivo diario (vasos)',
            value: settings.dailyGoal,
            min: 1,
            max: 20,
            onChanged: (v) {
              ref.read(settingsProvider.notifier).setDailyGoal(v);
              ref.read(waterProvider.notifier).setGoal(v);
              ref.read(achievementsProvider.notifier).unlockManual('customizer');
            },
          ),
          const SizedBox(height: 16),

          // Glass size
          GoalPicker(
            label: 'Tamano del vaso (ml)',
            value: settings.glassSizeMl,
            min: 100,
            max: 500,
            step: 50,
            onChanged: (v) {
              ref.read(settingsProvider.notifier).setGlassSizeMl(v);
              ref.read(waterProvider.notifier).setGlassSize(v);
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
              currentGlassSizeMl: settings.glassSizeMl,
              onApplyGoal: (glasses) {
                ref.read(settingsProvider.notifier).setDailyGoal(glasses);
                ref.read(waterProvider.notifier).setGoal(glasses);
                ref.read(achievementsProvider.notifier).unlockManual('customizer');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Objetivo actualizado a $glasses vasos'),
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
                color: AguaTheme.primaryBlue,
              ),
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
              activeColor: AguaTheme.primaryBlue,
            ),
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

          // Premium
          PremiumCard(isPremium: isPremium),

          // Privacy policy link
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip, color: AguaTheme.primaryBlue),
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
