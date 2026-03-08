import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../providers/challenge_provider.dart';

class WeeklyChallengeCard extends StatelessWidget {
  final ChallengeState challengeState;

  const WeeklyChallengeCard({super.key, required this.challengeState});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final challenge = challengeState.challenge;
    final completed = challengeState.completed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: completed
              ? [
                  AguaTheme.successGreen.withValues(alpha: 0.15),
                  AguaTheme.successGreen.withValues(alpha: 0.05),
                ]
              : [
                  colorScheme.primary.withValues(alpha: 0.12),
                  colorScheme.primary.withValues(alpha: 0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed
              ? AguaTheme.successGreen.withValues(alpha: 0.3)
              : colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : challenge.icon,
            size: 32,
            color: completed ? AguaTheme.successGreen : colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reto semanal',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  challenge.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: challengeState.progress,
                    minHeight: 6,
                    backgroundColor:
                        colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(
                      completed
                          ? AguaTheme.successGreen
                          : colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${challengeState.currentValue}/${challenge.targetValue}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: completed ? AguaTheme.successGreen : colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
