import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/premium_provider.dart';
import '../../../services/purchase_service.dart';

class PremiumCard extends ConsumerWidget {
  final bool isPremium;

  const PremiumCard({super.key, required this.isPremium});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isPremium) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium activo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Gracias por tu apoyo!',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(premiumProvider.notifier).setPremium(false);
                  },
                  icon: const Icon(Icons.bug_report, size: 16),
                  label: const Text('DEBUG: Desactivar Premium'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 40),
            const SizedBox(height: 12),
            Text(
              'AguaHoy Premium',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sin anuncios\nHistorial de 30 dias\nColores de widget',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => PurchaseService.buyPremium(),
              child: const Text('Comprar - 1.99€'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => PurchaseService.restorePurchases(),
              child: const Text('Restaurar compra'),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(premiumProvider.notifier).setPremium(true);
                },
                icon: const Icon(Icons.bug_report, size: 16),
                label: const Text('DEBUG: Activar Premium'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
