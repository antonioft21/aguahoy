import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/stats_provider.dart';
import '../../providers/history_provider.dart';
import '../../services/export_service.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static const _monthLabels = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(advancedStatsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadisticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exportar CSV',
            onPressed: () async {
              final service = ref.read(historyServiceProvider);
              final records = await service.getAllRecords();
              if (records.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No hay datos para exportar')),
                  );
                }
                return;
              }
              await ExportService.exportCsv(records);
            },
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top stats grid
            Row(
              children: [
                _StatTile(
                  icon: Icons.water_drop,
                  value: '${stats.totalLiters} L',
                  label: 'Total bebido',
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.local_drink,
                  value: '${stats.totalGlasses}',
                  label: 'Total registros',
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatTile(
                  icon: Icons.calendar_today,
                  value: '${stats.daysTracked}',
                  label: 'Dias registrados',
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.check_circle,
                  value: '${stats.goalMetPercent.toStringAsFixed(0)}%',
                  label: 'Dias cumplidos',
                  color: AguaTheme.successGreen,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Best day
            if (stats.bestDay != null) ...[
              _SectionTitle(text: 'Mejor dia'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events,
                          color: Colors.amber, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${stats.bestDay!.totalMl} ml',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(stats.bestDay!.dateKey),
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 30-day average
            _SectionTitle(text: 'Media 30 dias'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: colorScheme.primary, size: 32),
                    const SizedBox(width: 16),
                    Text(
                      '${stats.avgMl30d} ml/dia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Monthly chart
            if (stats.monthlyAvgMl.isNotEmpty) ...[
              _SectionTitle(text: 'Media mensual (${DateTime.now().year})'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 160,
                    child: _MonthlyChart(
                      monthlyAvgMl: stats.monthlyAvgMl,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateKey) {
    final d = DateTime.tryParse(dateKey);
    if (d == null) return dateKey;
    return '${d.day} ${_monthLabels[d.month - 1]} ${d.year}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final Map<int, int> monthlyAvgMl;
  final ColorScheme colorScheme;

  const _MonthlyChart({
    required this.monthlyAvgMl,
    required this.colorScheme,
  });

  static const _labels = [
    'E', 'F', 'M', 'A', 'M', 'J',
    'J', 'A', 'S', 'O', 'N', 'D',
  ];

  @override
  Widget build(BuildContext context) {
    final maxVal = monthlyAvgMl.values.fold<int>(1, (a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(12, (i) {
        final month = i + 1;
        final avg = monthlyAvgMl[month] ?? 0;
        final barHeight = maxVal > 0 ? (avg / maxVal) * 120 : 0.0;
        final hasData = monthlyAvgMl.containsKey(month);

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasData)
                Text(
                  avg.toString(),
                  style: TextStyle(
                    fontSize: 8,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: hasData
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
