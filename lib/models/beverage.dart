import 'package:flutter/material.dart';

class Beverage {
  final String id;
  final String name;
  final IconData icon;
  final double hydrationRatio; // 1.0 = 100%, 0.8 = 80%, -0.5 = dehydrating

  const Beverage({
    required this.id,
    required this.name,
    required this.icon,
    required this.hydrationRatio,
  });

  /// Effective ml of hydration for a given volume.
  int effectiveMl(int volumeMl) => (volumeMl * hydrationRatio).round();
}

const beverages = [
  Beverage(id: 'water', name: 'Agua', icon: Icons.water_drop, hydrationRatio: 1.0),
  Beverage(id: 'tea', name: 'Te', icon: Icons.emoji_food_beverage, hydrationRatio: 0.9),
  Beverage(id: 'coffee', name: 'Cafe', icon: Icons.coffee, hydrationRatio: 0.8),
  Beverage(id: 'juice', name: 'Zumo', icon: Icons.local_bar, hydrationRatio: 0.85),
  Beverage(id: 'milk', name: 'Leche', icon: Icons.breakfast_dining, hydrationRatio: 0.9),
  Beverage(id: 'soda', name: 'Refresco', icon: Icons.local_drink, hydrationRatio: 0.7),
  Beverage(id: 'beer', name: 'Cerveza', icon: Icons.sports_bar, hydrationRatio: -0.5),
];

final beverageMap = {for (final b in beverages) b.id: b};

/// Default beverage
const defaultBeverage = beverages; // index 0 = water
