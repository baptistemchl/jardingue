import 'package:flutter/material.dart';

enum PlanningActionType {
  sowingUnderCover(
    'Semis sous abri',
    '🏠',
    Color(0xFFFF9800),
  ),
  sowingOpenGround(
    'Semis pleine terre',
    '🌱',
    Color(0xFF4CAF50),
  ),
  transplanting(
    'Repiquage',
    '🔄',
    Color(0xFF9C27B0),
  ),
  planting(
    'Plantation',
    '🌿',
    Color(0xFF2196F3),
  ),
  harvest(
    'Récolte',
    '🧺',
    Color(0xFFE91E63),
  ),
  soilPreparation(
    'Préparation du sol',
    '🪴',
    Color(0xFF795548),
  ),
  mulching(
    'Paillage',
    '🍂',
    Color(0xFFFF8F00),
  ),
  fertilizing(
    'Fumure / Amendement',
    '💩',
    Color(0xFF5D4037),
  ),
  soilTurning(
    'Retournement du sol',
    '⛏️',
    Color(0xFF6D4C41),
  ),
  frostProtection(
    'Protection gel',
    '❄️',
    Color(0xFF42A5F5),
  ),
  watering(
    'Arrosage',
    '💧',
    Color(0xFF29B6F6),
  );

  final String label;
  final String emoji;
  final Color color;

  const PlanningActionType(
    this.label,
    this.emoji,
    this.color,
  );
}
