/// Données saisies par l'utilisateur pour créer ou éditer une plante
/// personnalisée. La couche repository transforme cet objet en
/// `PlantsCompanion` Drift avec `isUserModified = true` et un id ≥
/// 1_000_000 alloué automatiquement.
///
/// Les calendriers sont passés en JSON déjà encodé (format identique au
/// catalogue : `{"January": "Oui", "February": "Oui (sous abri)", ...}`)
/// pour réutiliser le parsing existant (`PlantJsonExtension.sowingMonths`
/// dans `plant_import_service.dart`).
class UserPlantInput {
  final String commonName;
  final String? latinName;
  final String categoryCode;
  final String? categoryLabel;

  // Espacements et profondeur (cm)
  final int? spacingBetweenPlants;
  final int? spacingBetweenRows;
  final int? plantingDepthCm;

  // Conditions de culture
  final String? sunExposure;
  final String? soilMoisturePreference;
  final String? soilType;
  final String? growingZone;
  final String? watering;
  final int? plantingMinTempC;

  // Calendriers (JSON encodé)
  final String? sowingCalendarJson;
  final String? plantingCalendarJson;
  final String? harvestCalendarJson;

  // Conseils
  final String? sowingRecommendation;
  final String? plantingAdvice;
  final String? careAdvice;
  final String? redFlags;
  final String? practicalTips;

  // Avancé
  final String? toxicity;
  final String? rotationFamily;

  // Emoji choisi manuellement par l'utilisateur. Null = laisser
  // PlantEmojiMapper déduire depuis commonName/categoryCode.
  final String? customEmoji;

  const UserPlantInput({
    required this.commonName,
    required this.categoryCode,
    this.latinName,
    this.categoryLabel,
    this.spacingBetweenPlants,
    this.spacingBetweenRows,
    this.plantingDepthCm,
    this.sunExposure,
    this.soilMoisturePreference,
    this.soilType,
    this.growingZone,
    this.watering,
    this.plantingMinTempC,
    this.sowingCalendarJson,
    this.plantingCalendarJson,
    this.harvestCalendarJson,
    this.sowingRecommendation,
    this.plantingAdvice,
    this.careAdvice,
    this.redFlags,
    this.practicalTips,
    this.toxicity,
    this.rotationFamily,
    this.customEmoji,
  });
}
