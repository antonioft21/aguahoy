import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/day_record.dart';

class HeatMapCalendar extends StatelessWidget {
  final List<DayRecord> records;
  final int weeks;

  const HeatMapCalendar({
    super.key,
    required this.records,
    this.weeks = 13, // ~3 months
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final recordMap = {for (final r in records) r.dateKey: r};
    final today = DateTime.now();

    // Build grid: columns = weeks, rows = 7 days (Mon-Sun)
    // Start from the Monday of (weeks) ago
    final endDate = today;
    final startDate = endDate.subtract(Duration(days: weeks * 7 - 1));
    // Align to Monday
    final alignedStart =
        startDate.subtract(Duration(days: (startDate.weekday - 1)));

    final totalDays = endDate.difference(alignedStart).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    const cellGap = 3.0;
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month, size: 18, color: AguaTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              'Calendario',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const dayLabelWidth = 16.0;
            const dayLabelGap = 4.0;
            final gridWidth = constraints.maxWidth - dayLabelWidth - dayLabelGap;
            final cellTotal = gridWidth / totalWeeks;
            final adaptedCellSize = (cellTotal - cellGap).clamp(8.0, 16.0);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day labels column
                SizedBox(
                  width: dayLabelWidth,
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      return SizedBox(
                        height: adaptedCellSize + cellGap,
                        child: Center(
                          child: Text(
                            dayLabels[dayIndex],
                            style: TextStyle(
                              fontSize: 9,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(width: dayLabelGap),
                // Grid — auto-sized to fill width
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalWeeks, (weekIndex) {
                      return Column(
                        children: List.generate(7, (dayIndex) {
                          final dayOffset = weekIndex * 7 + dayIndex;
                          final date = alignedStart.add(Duration(days: dayOffset));

                          // Don't show future days
                          if (date.isAfter(today)) {
                            return SizedBox(
                              width: adaptedCellSize + cellGap,
                              height: adaptedCellSize + cellGap,
                            );
                          }

                          final key =
                              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          final record = recordMap[key];
                          final progress = record?.progress ?? 0.0;
                          final isToday = date.year == today.year &&
                              date.month == today.month &&
                              date.day == today.day;

                          return Padding(
                            padding: EdgeInsets.all(cellGap / 2),
                            child: Tooltip(
                              message: _tooltipText(key, record),
                              child: Container(
                                width: adaptedCellSize,
                                height: adaptedCellSize,
                                decoration: BoxDecoration(
                                  color: _cellColor(progress, colorScheme),
                                  borderRadius: BorderRadius.circular(3),
                                  border: isToday
                                      ? Border.all(
                                          color: colorScheme.onSurface,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Menos',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            for (final level in [0.0, 0.25, 0.5, 0.75, 1.0])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _cellColor(level, colorScheme),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Text(
              'Mas',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _cellColor(double progress, ColorScheme colorScheme) {
    if (progress <= 0) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    } else if (progress < 0.25) {
      return AguaTheme.primaryBlue.withValues(alpha: 0.2);
    } else if (progress < 0.5) {
      return AguaTheme.primaryBlue.withValues(alpha: 0.4);
    } else if (progress < 0.75) {
      return AguaTheme.primaryBlue.withValues(alpha: 0.6);
    } else if (progress < 1.0) {
      return AguaTheme.primaryBlue.withValues(alpha: 0.8);
    } else {
      return AguaTheme.primaryBlue;
    }
  }

  String _tooltipText(String dateKey, DayRecord? record) {
    if (record == null) return '$dateKey: sin datos';
    return '$dateKey: ${record.glasses}/${record.goalGlasses} vasos';
  }
}
