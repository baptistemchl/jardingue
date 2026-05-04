import 'package:drift/drift.dart';

/// Table des arbres fruitiers (catalogue)
class FruitTrees extends Table {
  IntColumn get id => integer()();

  TextColumn get commonName => text()();

  TextColumn get latinName => text().nullable()();

  // Catégorie
  TextColumn get category => text().nullable()();

  TextColumn get subcategory => text().nullable()();

  TextColumn get emoji => text().withDefault(const Constant('🌳'))();

  TextColumn get description => text().nullable()();

  // Dimensions
  RealColumn get heightAdultM => real().nullable()();

  RealColumn get spreadAdultM => real().nullable()();

  TextColumn get growthRate => text().nullable()();

  IntColumn get lifespanYears => integer().nullable()();

  // Rusticité
  TextColumn get hardinessZone => text().nullable()();

  IntColumn get coldResistanceCelsius => integer().nullable()();

  // Conditions de culture
  TextColumn get sunExposure => text().nullable()();

  TextColumn get soilType => text().nullable()();

  TextColumn get soilPh => text().nullable()();

  TextColumn get waterNeeds => text().nullable()();

  BoolColumn get droughtTolerance =>
      boolean().withDefault(const Constant(false))();

  // Pollinisation
  BoolColumn get selfFertile => boolean().withDefault(const Constant(false))();

  TextColumn get pollinationDetails => text().nullable()();

  // Périodes
  TextColumn get floweringPeriod => text().nullable()();

  TextColumn get harvestPeriod => text().nullable()();

  IntColumn get yearsToFirstFruit => integer().nullable()();

  RealColumn get yieldKgPerTree => real().nullable()();

  // Plantation
  TextColumn get plantingPeriod => text().nullable()();

  RealColumn get plantingDistanceM => real().nullable()();

  // Tailles
  TextColumn get pruningTrainingPeriod => text().nullable()();

  TextColumn get pruningMaintenancePeriod => text().nullable()();

  // Problèmes (JSON)
  TextColumn get diseases => text().nullable()();

  TextColumn get pests => text().nullable()();

  // Culture en pot
  BoolColumn get containerSuitable =>
      boolean().withDefault(const Constant(false))();

  IntColumn get containerMinSizeL => integer().nullable()();

  // Variétés populaires (JSON)
  TextColumn get popularVarieties => text().nullable()();

  // Adaptation climatique (JSON: {cold, temperate, hot})
  TextColumn get climateAdaptation => text().nullable()();

  // Toxicité (null si non toxique)
  TextColumn get toxicity => text().nullable()();

  // Conseils pratiques de culture
  TextColumn get practicalTips => text().nullable()();

  // Métadonnées
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des arbres fruitiers de l'utilisateur (son verger)
class UserFruitTrees extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get fruitTreeId => integer().references(FruitTrees, #id)();

  // Personnalisation
  TextColumn get nickname => text().nullable()();

  TextColumn get variety => text().nullable()();

  // Infos plantation
  DateTimeColumn get plantingDate => dateTime().nullable()();

  TextColumn get location => text().nullable()();

  TextColumn get notes => text().nullable()();

  // Suivi
  TextColumn get healthStatus =>
      text().withDefault(const Constant('good'))(); // good, warning, poor

  DateTimeColumn get lastPruningDate => dateTime().nullable()();

  DateTimeColumn get lastHarvestDate => dateTime().nullable()();

  RealColumn get lastYieldKg => real().nullable()();

  // Photos (JSON array de chemins)
  TextColumn get photos => text().nullable()();

  // Métadonnées
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Pieges a pheromones poses sur un arbre fruitier de l'utilisateur (v15).
///
/// Une ligne par piege physique pose. Le renouvellement se fait en mettant
/// a jour `installedAt` (action quick-renew) ou en supprimant + recreant
/// (changement de type, deplacement...).
///
/// `lifetimeDays` est copie depuis le default du `trapType` au moment de
/// l'ajout, mais reste editable par l'utilisateur (les capsules longue
/// duree vs standard ont des durees differentes meme pour un meme ravageur).
class PheromoneTraps extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Lien vers l'arbre cible. Cascade delete fait par le repository.
  IntColumn get userFruitTreeId =>
      integer().references(UserFruitTrees, #id)();

  /// Identifiant du type (PheromoneTrapType.name).
  TextColumn get trapType => text()();

  /// Date de pose (= date de mise en service du diffuseur courant).
  DateTimeColumn get installedAt => dateTime()();

  /// Duree de vie de la capsule en jours.
  IntColumn get lifetimeDays => integer()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
