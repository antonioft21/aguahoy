import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../providers/history_provider.dart';
import '../../providers/premium_provider.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/premium_gate.dart';
import 'widgets/day_bar.dart';
import 'widgets/stats_card.dart';
import 'widgets/heat_map_calendar.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);
    final maxDays = isPremium ? 30 : 7;
    final historyAsync = ref.watch(recentHistoryProvider(maxDays));
    final streakAsync = ref.watch(streakProvider);
    final avgAsync = ref.watch(weeklyAverageProvider);
    final storage = ref.read(storageServiceProvider);
    final freezes = storage.streakFreezes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadisticas',
            onPressed: () => Navigator.pushNamed(context, '/stats'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats row
            Row(
              children: [
                Expanded(
                  child: streakAsync.when(
                    data: (streak) => StatsCard(
                      label: 'Racha',
                      value: '$streak dias',
                      icon: Icons.local_fire_department,
                    ),
                    loading: () => const StatsCard(
                      label: 'Racha',
                      value: '...',
                      icon: Icons.local_fire_department,
                    ),
                    error: (_, __) => const StatsCard(
                      label: 'Racha',
                      value: '0',
                      icon: Icons.local_fire_department,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: avgAsync.when(
                    data: (avg) => StatsCard(
                      label: 'Media 7d',
                      value: '${avg.round()} ml',
                      icon: Icons.trending_up,
                    ),
                    loading: () => const StatsCard(
                      label: 'Media 7d',
                      value: '...',
                      icon: Icons.trending_up,
                    ),
                    error: (_, __) => const StatsCard(
                      label: 'Media 7d',
                      value: '0',
                      icon: Icons.trending_up,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    label: 'Freezes',
                    value: '$freezes',
                    icon: Icons.ac_unit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Heat map calendar
            ref.watch(recentHistoryProvider(91)).when(
              data: (records) => HeatMapCalendar(records: records),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            // History list
            Expanded(
              child: historyAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return Center(
                      child: Text(
                        'Aun no hay historial.\nEmpieza a tomar agua!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return DayBar(record: record);
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            // Premium gate for >7 days
            if (!isPremium)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: PremiumGate(
                  message: 'Desbloquea 30 dias de historial con Premium',
                ),
              ),
            // Ad banner
            if (!isPremium) const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}
