import 'package:flutter/material.dart';
import '../../../models/beverage.dart';

class BeverageBreakdownRow extends StatelessWidget {
  final Map<String, int> mlByBeverage;

  const BeverageBreakdownRow({super.key, required this.mlByBeverage});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (mlByBeverage.isEmpty) {
      return Text(
        'Sin registros hoy',
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final sorted = mlByBeverage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: sorted.map((entry) {
        final bev = beverageMap[entry.key];
        if (bev == null) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(bev.icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              '${bev.name} ${entry.value} ml',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
