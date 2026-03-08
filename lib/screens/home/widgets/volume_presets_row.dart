import 'package:flutter/material.dart';

class VolumePresetsRow extends StatelessWidget {
  final ValueChanged<int> onAddDrink;

  const VolumePresetsRow({super.key, required this.onAddDrink});

  static const _presets = [
    (label: 'Taza', ml: 150, icon: Icons.coffee),
    (label: 'Vaso', ml: 250, icon: Icons.local_drink),
    (label: 'Botella', ml: 500, icon: Icons.water_drop),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        ..._presets.map((p) => _PresetButton(
              label: p.label,
              ml: p.ml,
              icon: p.icon,
              onTap: () => onAddDrink(p.ml),
              colorScheme: colorScheme,
            )),
        _PresetButton(
          label: 'Otro',
          ml: null,
          icon: Icons.tune,
          onTap: () => _showCustomDialog(context),
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  void _showCustomDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cantidad personalizada'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ml (50 - 2000)',
            suffixText: 'ml',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 50 && value <= 2000) {
                Navigator.pop(ctx);
                onAddDrink(value);
              }
            },
            child: const Text('Anadir'),
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final int? ml;
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _PresetButton({
    required this.label,
    required this.ml,
    required this.icon,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                ml != null ? '$label\n${ml}ml' : label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
