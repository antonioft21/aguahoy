import 'package:flutter/material.dart';

class MlLabel extends StatelessWidget {
  final int currentMl;
  final int goalMl;

  const MlLabel({
    super.key,
    required this.currentMl,
    required this.goalMl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$currentMl',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          TextSpan(
            text: ' / $goalMl ml',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
