import 'package:flutter/material.dart';
import '../../../core/date_utils.dart';
import '../../../core/theme.dart';
import '../../../models/day_record.dart';

class DayBar extends StatelessWidget {
  final DayRecord record;

  const DayBar({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final barColor =
        record.goalMet ? AguaTheme.successGreen : AguaTheme.primaryBlue;
    final isToday = record.dateKey == AppDateUtils.todayKey();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                isToday ? 'Hoy' : AppDateUtils.shortLabel(record.dateKey),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isToday ? AguaTheme.primaryBlue : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: record.progress,
                  minHeight: 16,
                  backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 48,
              child: Text(
                '${record.glasses}/${record.goalGlasses}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ),
            if (record.goalMet)
              const Icon(Icons.check_circle, size: 18, color: AguaTheme.successGreen)
            else
              const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }
}
