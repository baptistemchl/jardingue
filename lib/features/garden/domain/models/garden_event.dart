import 'package:flutter/material.dart';
import '../../../../core/services/database/app_database.dart';

/// Types d'événements enregistrés par l'utilisateur
enum GardenEventType {
  sowing('Semis', '🌱', Color(0xFF4CAF50)),
  sowingUnderCover('Semis sous abri', '🏠', Color(0xFFFF9800)),
  sowingOpenGround('Semis pleine terre', '🌱', Color(0xFF4CAF50)),
  planting('Plantation', '🌿', Color(0xFF8BC34A)),
  watering('Arrosage', '💧', Color(0xFF03A9F4)),
  harvest('Récolte', '🧺', Color(0xFFE91E63));

  final String label;
  final String emoji;
  final Color color;

  const GardenEventType(this.label, this.emoji, this.color);

  /// Retourne true si c'est un type de semis
  bool get isSowing =>
      this == sowing ||
      this == sowingUnderCover ||
      this == sowingOpenGround;

  static GardenEventType fromString(String s) =>
      values.firstWhere((e) => e.name == s, orElse: () => watering);
}

/// Un événement jardin avec les détails associés
class GardenEventWithDetails {
  final GardenEvent event;
  final GardenPlant? gardenPlant;
  final Plant? plant;
  final Garden? garden;

  const GardenEventWithDetails({
    required this.event,
    this.gardenPlant,
    this.plant,
    this.garden,
  });

  GardenEventType get type => GardenEventType.fromString(event.eventType);

  String get plantName => plant?.commonName ?? 'Plante inconnue';

  String get gardenName => garden?.name ?? '';

  /// True si l'événement est lié à un potager
  bool get hasGarden => gardenPlant != null && garden != null;
}
