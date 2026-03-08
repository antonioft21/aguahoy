import 'package:flutter/material.dart';

class HydrationCalculator extends StatefulWidget {
  final int? savedWeightKg;
  final int savedActivityLevel;
  final ValueChanged<int> onApplyGoal;

  const HydrationCalculator({
    super.key,
    this.savedWeightKg,
    required this.savedActivityLevel,
    required this.onApplyGoal,
  });

  @override
  State<HydrationCalculator> createState() => _HydrationCalculatorState();
}

class _HydrationCalculatorState extends State<HydrationCalculator> {
  late int _weightKg;
  late int _activityLevel;

  static const _activityLabels = ['Sedentario', 'Moderado', 'Activo'];
  static const _activityMlPerKg = [30.0, 35.0, 40.0];

  @override
  void initState() {
    super.initState();
    _weightKg = widget.savedWeightKg ?? 70;
    _activityLevel = widget.savedActivityLevel;
  }

  int get _recommendedMl =>
      (_weightKg * _activityMlPerKg[_activityLevel]).round();

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
                Icon(Icons.calculate, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Calculadora de hidratacion',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weight slider
            Text(
              'Peso: $_weightKg kg',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Slider(
              value: _weightKg.toDouble(),
              min: 30,
              max: 150,
              divisions: 120,
              activeColor: colorScheme.primary,
              label: '$_weightKg kg',
              onChanged: (v) => setState(() => _weightKg = v.round()),
            ),

            // Activity level
            Text(
              'Actividad: ${_activityLabels[_activityLevel]}',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(3, (i) {
                final isSelected = i == _activityLevel;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: i > 0 ? 4 : 0,
                      right: i < 2 ? 4 : 0,
                    ),
                    child: ChoiceChip(
                      label: Text(
                        _activityLabels[i],
                        style: TextStyle(fontSize: 12),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _activityLevel = i),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Recommendation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Recomendado: $_recommendedMl ml/dia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => widget.onApplyGoal(_recommendedMl),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Aplicar objetivo'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
