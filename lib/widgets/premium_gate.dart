import 'package:flutter/material.dart';
import '../core/theme.dart';

class PremiumGate extends StatelessWidget {
  final String message;

  const PremiumGate({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AguaTheme.primaryBlue.withValues(alpha: 0.1),
            AguaTheme.darkBlue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AguaTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock, color: AguaTheme.primaryBlue, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(Icons.star, size: 18),
            label: const Text('Ver Premium'),
          ),
        ],
      ),
    );
  }
}
