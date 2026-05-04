import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/services/database/app_database.dart';
import 'garden_event.dart';
import 'garden_plant_with_details.dart';

/// Type de soin recurrent pris en charge par le systeme generique de rappels.
///
/// Chaque kind sait : a quel `GardenEventType` il correspond pour le log
/// dans le calendrier, quel emoji/couleur afficher, et quelle icone Phosphor
/// utiliser dans l'UI.
enum CareKind {
  watering(
    eventType: GardenEventType.watering,
    emoji: '💧',
    accentColor: Color(0xFF42A5F5),
    bgColor: Color(0xFFE3F2FD),
  ),
  fertilizing(
    eventType: GardenEventType.fertilizer,
    emoji: '🌾',
    accentColor: Color(0xFF8D6E63),
    bgColor: Color(0xFFEFEBE9),
  );

  const CareKind({
    required this.eventType,
    required this.emoji,
    required this.accentColor,
    required this.bgColor,
  });

  final GardenEventType eventType;
  final String emoji;
  final Color accentColor;
  final Color bgColor;

  /// Icone Phosphor associee. Les emojis ne sont pas un type Phosphor donc
  /// on resoud a runtime via une fabrique (sinon `const` impossible).
  IconData icon(PhosphorIconsStyle style) {
    switch (this) {
      case CareKind.watering:
        return PhosphorIcons.drop(style);
      case CareKind.fertilizing:
        return PhosphorIcons.plant(style);
    }
  }
}

/// Hint contextuel optionnel sur un rappel (ex: "ne pas arroser, pluie
/// prevue"). Aujourd'hui utilise uniquement par CareKind.watering.
class CareHint {
  /// Si true, on doit recommander a l'utilisateur de reporter l'action.
  final bool skip;

  /// Message a afficher (deja localise par le provider).
  final String message;

  const CareHint({required this.skip, required this.message});
}

/// Rappel d'un soin recurrent pour une plante d'un potager.
///
/// Generique : structure unique pour arrosage, fertilisation et tout autre
/// soin futur base sur (date de reference + intervalle).
class CareReminder {
  final CareKind kind;
  final GardenPlantWithDetails gardenPlant;
  final Garden garden;

  /// Derniere occurrence du soin (null si jamais effectue).
  final DateTime? lastDate;

  /// Intervalle attendu en jours.
  final int frequencyDays;

  /// Prochaine echeance calculee (date du jour si jamais effectue).
  final DateTime nextDue;

  /// True si l'echeance est passee ou aujourd'hui.
  final bool isOverdue;

  /// Hint contextuel (meteo pour l'arrosage, etc.). Null si pas de hint.
  final CareHint? hint;

  const CareReminder({
    required this.kind,
    required this.gardenPlant,
    required this.garden,
    required this.lastDate,
    required this.frequencyDays,
    required this.nextDue,
    required this.isOverdue,
    this.hint,
  });

  /// True si on doit recommander a l'utilisateur de reporter (hint.skip).
  bool get shouldSkip => hint?.skip ?? false;

  /// Nombre de jours depuis la derniere occurrence (-1 si jamais).
  int get daysSinceLast {
    if (lastDate == null) return -1;
    return DateTime.now().difference(lastDate!).inDays;
  }

  /// Nombre de jours avant la prochaine echeance (negatif si en retard).
  int get daysUntilNext => nextDue.difference(DateTime.now()).inDays;
}
