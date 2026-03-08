import 'package:flutter/material.dart';

class ReminderConfig extends StatelessWidget {
  final bool enabled;
  final int intervalMin;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onIntervalChanged;

  const ReminderConfig({
    super.key,
    required this.enabled,
    required this.intervalMin,
    required this.onEnabledChanged,
    required this.onIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text(
                'Recordatorios',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                enabled ? 'Te avisaremos para que bebas agua' : 'Desactivados',
                style: const TextStyle(fontSize: 13),
              ),
              value: enabled,
              onChanged: onEnabledChanged,
              activeColor: Theme.of(context).colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            if (enabled) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recordar cada',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  DropdownButton<int>(
                    value: intervalMin,
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 min')),
                      DropdownMenuItem(value: 60, child: Text('1 hora')),
                      DropdownMenuItem(value: 90, child: Text('1.5 horas')),
                      DropdownMenuItem(value: 120, child: Text('2 horas')),
                    ],
                    onChanged: (v) {
                      if (v != null) onIntervalChanged(v);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
