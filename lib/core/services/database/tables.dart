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

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
