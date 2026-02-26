import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class GlassIconsRow extends StatelessWidget {
  final int filled;
  final int total;

  const GlassIconsRow({
    super.key,
    required this.filled,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: List.generate(total, (i) {
        final isFilled = i < filled;
        return Icon(
          Icons.water_drop,
          size: 28,
          color: isFilled
              ? AguaTheme.primaryBlue
              : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        );
      }),
    );
  }
}
