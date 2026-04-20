import 'package:drift/drift.dart';

/// Table principale des plantes
class Plants extends Table {
  IntColumn get id => integer()();

  TextColumn get commonName => text()();

  TextColumn get latinName => text().nullable()();

  // Catégorie
  TextColumn get categoryCode => text().nullable()();

  TextColumn get categoryLabel => text().nullable()();

  // Espacements
  IntColumn get spacingBetweenPlants => integer().nullable()();

  IntColumn get spacingBetweenRows => integer().nullable()();

  IntColumn get plantingDepthCm => integer().nullable()();

  // Conditions de culture
  TextColumn get sunExposure => text().nullable()();

  TextColumn get soilMoisturePreference => text().nullable()();

  TextColumn get soilTreatmentAdvice => text().nullable()();

  TextColumn get soilType => text().nullable()();

  TextColumn get growingZone => text().nullable()();

  TextColumn get watering => text().nullable()();

  // Températures
  IntColumn get plantingMinTempC => integer().nullable()();

  TextColumn get plantingWeatherConditions => text().nullable()();

  // Périodes (texte descriptif)
  TextColumn get sowingUnderCoverPeriod => text().nullable()();

  TextColumn get sowingOpenGroundPeriod => text().nullable()();

  TextColumn get transplantingPeriod => text().nullable()();

  TextColumn get harvestPeriod => text().nullable()();

  // Conseils
  TextColumn get sowingRecommendation => text().nullable()();

  TextColumn get cultivationGreenhouse => text().nullable()();

  TextColumn get plantingAdvice => text().nullable()();

  TextColumn get careAdvice => text().nullable()();

  TextColumn get redFlags => text().nullable()();

  // Nuisibles (stocké en JSON)
  TextColumn get mainDestroyers => text().nullable()();

  // Calendriers (stockés en JSON pour simplifier)
  TextColumn get sowingCalendar => text().nullable()();

  TextColumn get plantingCalendar => text().nullable()();

  TextColumn get harvestCalendar => text().nullable()();

  // Adaptation climatique (JSON: {cold, temperate, hot})
  TextColumn get climateAdaptation => text().nullable()();

  // Toxicité (null si non toxique)
  TextColumn get toxicity => text().nullable()();

  // Conseils pratiques complémentaires
  TextColumn get practicalTips => text().nullable()();

  // Métadonnées
  BoolColumn get isUserModified =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des relations plantes compagnes
class PlantCompanions extends Table {
  IntColumn get plantId => integer().references(Plants, #id)();

  IntColumn get companionId => integer().references(Plants, #id)();

  @override
  Set<Column> get primaryKey => {plantId, companionId};
}

/// Table des relations plantes antagonistes
class PlantAntagonists extends Table {
  IntColumn get plantId => integer().references(Plants, #id)();

  IntColumn get antagonistId => integer().references(Plants, #id)();

  @override
  Set<Column> get primaryKey => {plantId, antagonistId};
}

/// Table pour les potagers de l'utilisateur
class Gardens extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  IntColumn get widthCells => integer().withDefault(const Constant(10))();

  IntColumn get heightCells => integer().withDefault(const Constant(10))();

  IntColumn get cellSizeCm => integer().withDefault(const Constant(30))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table pour les plantes placées dans un potager
class GardenPlants extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get gardenId => integer().references(Gardens, #id)();

  IntColumn get plantId => integer().references(Plants, #id)();

  IntColumn get gridX => integer()();

  IntColumn get gridY => integer()();

  IntColumn get widthCells => integer().withDefault(const Constant(1))();

  IntColumn get heightCells => integer().withDefault(const Constant(1))();

  DateTimeColumn get plantedAt => dateTime().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get sowedAt => dateTime().nullable()();

  IntColumn get wateringFrequencyDays => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table des plantes sélectionnées pour la planification
class SelectedPlantsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get plantId =>
      integer().references(Plants, #id)();

  DateTimeColumn get addedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'selected_plants';
}

/// Table de suivi des tâches de planification complétées
class CompletedPlanningTasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Clé unique de la tâche (ex: "jan_plan_garden" ou "plant_1_sowing_3")
  TextColumn get taskKey => text()();

  /// Plant associé (null pour les tâches potagères)
  IntColumn get plantId =>
      integer().nullable().references(Plants, #id)();

  IntColumn get year => integer()();

  IntColumn get month => integer()();

  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'completed_planning_tasks';
}

/// Table pour les événements du jardin (semis, plantation, arrosage, récolte)
class GardenEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Lien vers une plante dans un potager (optionnel)
  IntColumn get gardenPlantId =>
      integer().nullable().references(GardenPlants, #id)();

  /// Lien direct vers le catalogue de plantes (pour événements sans potager)
  IntColumn get plantId => integer().nullable().references(Plants, #id)();

  TextColumn get eventType => text()();

  DateTimeColumn get eventDate => dateTime()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
