import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class AccentPicker extends StatelessWidget {
  final int selectedIndex;
  final bool isPremium;
  final ValueChanged<int> onChanged;

  const AccentPicker({
    super.key,
    required this.selectedIndex,
    required this.isPremium,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Color de acento',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (!isPremium) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Premium',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(AccentColors.colors.length, (i) {
                final color = AccentColors.colors[i];
                final isSelected = i == selectedIndex;
                final canSelect = isPremium || i == 0; // Free users only get blue

                return GestureDetector(
                  onTap: canSelect ? () => onChanged(i) : null,
                  child: Opacity(
                    opacity: canSelect ? 1.0 : 0.4,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : (!canSelect
                              ? const Icon(Icons.lock, color: Colors.white, size: 14)
                              : null),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
