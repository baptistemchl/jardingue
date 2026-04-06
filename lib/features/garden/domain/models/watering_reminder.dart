import 'garden_plant_with_details.dart';
import '../../../../core/services/database/app_database.dart';

/// Rappel d'arrosage pour une plante dans un jardin
class WateringReminder {
  final GardenPlantWithDetails gardenPlant;
  final Garden garden;
  final DateTime? lastWatered;
  final int frequencyDays;
  final DateTime nextWateringDue;
  final bool isOverdue;
  final bool weatherSaysSkip;
  final String weatherAdvice;

  const WateringReminder({
    required this.gardenPlant,
    required this.garden,
    required this.lastWatered,
    required this.frequencyDays,
    required this.nextWateringDue,
    required this.isOverdue,
    required this.weatherSaysSkip,
    required this.weatherAdvice,
  });

  /// Nombre de jours depuis le dernier arrosage
  int get daysSinceLastWatering {
    if (lastWatered == null) return -1;
    return DateTime.now().difference(lastWatered!).inDays;
  }

  /// Nombre de jours avant le prochain arrosage (négatif si en retard)
  int get daysUntilNext {
    return nextWateringDue.difference(DateTime.now()).inDays;
  }
}
