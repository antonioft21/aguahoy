import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class GoalPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const GoalPicker({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: value > min
                      ? () => onChanged(value - step)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AguaTheme.primaryBlue,
                ),
                const SizedBox(width: 16),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: value < max
                      ? () => onChanged(value + step)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AguaTheme.primaryBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
