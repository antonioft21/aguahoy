import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

const achievements = [
  Achievement(
    id: 'first_glass',
    title: 'Primera Gota',
    description: 'Registra tu primer vaso de agua',
    icon: Icons.water_drop,
  ),
  Achievement(
    id: 'goal_met',
    title: 'Objetivo Cumplido',
    description: 'Cumple tu objetivo diario por primera vez',
    icon: Icons.check_circle,
  ),
  Achievement(
    id: 'streak_3',
    title: 'Tres en Racha',
    description: 'Mantén una racha de 3 dias',
    icon: Icons.local_fire_department,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Semana Perfecta',
    description: 'Mantén una racha de 7 dias',
    icon: Icons.star,
  ),
  Achievement(
    id: 'streak_14',
    title: 'Dos Semanas',
    description: 'Mantén una racha de 14 dias',
    icon: Icons.military_tech,
  ),
  Achievement(
    id: 'streak_30',
    title: 'Mes de Agua',
    description: 'Mantén una racha de 30 dias',
    icon: Icons.emoji_events,
  ),
  Achievement(
    id: 'double_goal',
    title: 'Doble Meta',
    description: 'Bebe el doble de tu objetivo en un dia',
    icon: Icons.bolt,
  ),
  Achievement(
    id: 'liter',
    title: 'Litro de Oro',
    description: 'Bebe 1 litro o mas en un dia',
    icon: Icons.workspace_premium,
  ),
  Achievement(
    id: 'glasses_50',
    title: 'Medio Centenar',
    description: 'Registra 50 vasos en total',
    icon: Icons.looks_5,
  ),
  Achievement(
    id: 'glasses_100',
    title: 'Centenario',
    description: 'Registra 100 vasos en total',
    icon: Icons.looks,
  ),
  Achievement(
    id: 'glasses_500',
    title: 'Leyenda del Agua',
    description: 'Registra 500 vasos en total',
    icon: Icons.diamond,
  ),
  Achievement(
    id: 'night_owl',
    title: 'Nocturno',
    description: 'Registra agua despues de las 22:00',
    icon: Icons.nightlight,
  ),
  Achievement(
    id: 'early_bird',
    title: 'Madrugador',
    description: 'Registra agua antes de las 7:00',
    icon: Icons.wb_sunny,
  ),
  Achievement(
    id: 'explorer',
    title: 'Explorador',
    description: 'Visita la pantalla de historial',
    icon: Icons.explore,
  ),
  Achievement(
    id: 'customizer',
    title: 'Personalizador',
    description: 'Cambia el tamano de vaso o el objetivo',
    icon: Icons.tune,
  ),
];

/// Map for quick lookup by id.
final achievementMap = {for (final a in achievements) a.id: a};
