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

  // Famille botanique pour la rotation des cultures (v10)
  // Ex: "solanaceae", "fabaceae", "brassicaceae"...
  TextColumn get rotationFamily => text().nullable()();

  // Frequence de fertilisation par defaut (jours), issue du catalogue (v15).
  // Sert de fallback quand l'utilisateur n'a pas defini sa propre valeur sur
  // le GardenPlant (sinon: defaultFertilizationFrequencyDays(categoryCode)).
  IntColumn get fertilizationFrequencyDays => integer().nullable()();

  // Emoji choisi manuellement par l'utilisateur (v16). Quand non null,
  // remplace l'emoji déduit de commonName/categoryCode dans
  // PlantEmojiMapper. Réservé aux plantes user (isUserModified=true).
  TextColumn get customEmoji => text().nullable()();

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

/// Amendements appliqués à une zone du potager (fumure, compost,
/// paillage, engrais vert, chaulage…). Datés et géolocalisés en cellules.
/// (v11)
class GardenAmendments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get gardenId => integer().references(Gardens, #id)();

  /// Code du type d'amendement : "fumure", "compost", "paillage",
  /// "engrais_vert", "chaulage".
  TextColumn get type => text()();

  IntColumn get gridX => integer()();
  IntColumn get gridY => integer()();
  IntColumn get widthCells => integer()();
  IntColumn get heightCells => integer()();

  DateTimeColumn get appliedAt => dateTime()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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

  // Année de référence du potager (v10)
  IntColumn get year => integer().nullable()();

  // Potager dont celui-ci est la suite (v10)
  IntColumn get previousGardenId =>
      integer().nullable().references(Gardens, #id)();

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

  // Couleur perso choisie par l'utilisateur pour ce pied placé (v19).
  // Stockée en ARGB int (ex: 0xFFFF5722). Quand null, on retombe sur la
  // couleur déduite de categoryCode dans GardenPlantWithDetails.color.
  IntColumn get customColor => integer().nullable()();

  // Frequence de fertilisation personnalisee par l'utilisateur (jours, v15).
  // Si null : on retombe sur Plants.fertilizationFrequencyDays puis sur
  // defaultFertilizationFrequencyDays(categoryCode).
  IntColumn get fertilizingFrequencyDays => integer().nullable()();

  // Culture précédente manuelle (rotation) (v10)
  IntColumn get previousCropPlantId =>
      integer().nullable().references(Plants, #id)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// SelectedPlantsTable retiree en v13. La planification lit desormais
// directement les plantes posees dans `garden_plants` ∪ celles ayant un
// event dans `garden_events`. La migration v12->v13 convertit les lignes
// orphelines en events `planting` puis drop la table.

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

/// Table pour les événements du jardin (semis, plantation, arrosage, récolte,
/// entretien : engrais, paillage, anti-limaces, traitement).
class GardenEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Lien vers une plante dans un potager (optionnel)
  IntColumn get gardenPlantId =>
      integer().nullable().references(GardenPlants, #id)();

  /// Lien direct vers le catalogue de plantes (pour événements sans potager)
  IntColumn get plantId => integer().nullable().references(Plants, #id)();

  /// Lien direct vers un potager (utilise pour les actions d'entretien
  /// applicables a un potager entier sans plante specifique : paillage
  /// general, anti-limaces, etc.).
  IntColumn get gardenId =>
      integer().nullable().references(Gardens, #id)();

  TextColumn get eventType => text()();

  DateTimeColumn get eventDate => dateTime()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
