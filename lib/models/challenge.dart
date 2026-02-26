import 'package:flutter/material.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int targetValue;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetValue,
  });
}

/// Pool of weekly challenges. One is picked per week based on week number.
const weeklyChallenges = [
  Challenge(
    id: 'total_glasses_50',
    title: 'Maraton de agua',
    description: 'Bebe 50 vasos esta semana',
    icon: Icons.emoji_events,
    targetValue: 50,
  ),
  Challenge(
    id: 'goal_5_days',
    title: 'Constancia',
    description: 'Cumple tu objetivo 5 de 7 dias',
    icon: Icons.calendar_today,
    targetValue: 5,
  ),
  Challenge(
    id: 'total_glasses_70',
    title: 'Super hidratacion',
    description: 'Bebe 70 vasos esta semana',
    icon: Icons.water,
    targetValue: 70,
  ),
  Challenge(
    id: 'goal_7_days',
    title: 'Semana perfecta',
    description: 'Cumple tu objetivo los 7 dias',
    icon: Icons.star,
    targetValue: 7,
  ),
  Challenge(
    id: 'total_glasses_40',
    title: 'Buen comienzo',
    description: 'Bebe 40 vasos esta semana',
    icon: Icons.water_drop,
    targetValue: 40,
  ),
  Challenge(
    id: 'goal_3_days',
    title: 'Tres seguidos',
    description: 'Cumple tu objetivo 3 dias seguidos',
    icon: Icons.looks_3,
    targetValue: 3,
  ),
];
