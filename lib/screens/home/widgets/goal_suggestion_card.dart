import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class GoalSuggestionCard extends StatelessWidget {
  final int currentGoal;
  final int streak;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const GoalSuggestionCard({
    super.key,
    required this.currentGoal,
    required this.streak,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final newGoal = currentGoal + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.15),
            Colors.amber.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$streak dias cumpliendo tu objetivo!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close, size: 18, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Subir objetivo a $newGoal vasos?',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: FilledButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.arrow_upward, size: 16),
              label: Text('Subir a $newGoal vasos'),
              style: FilledButton.styleFrom(
                backgroundColor: AguaTheme.primaryBlue,
                textStyle: const TextStyle(fontSize: 13),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
