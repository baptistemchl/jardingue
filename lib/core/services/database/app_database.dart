import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'orchard_tables.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Plants,
    PlantCompanions,
    PlantAntagonists,
    Gardens,
    GardenPlants,
    GardenEvents,
    FruitTrees,
    UserFruitTrees,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Pour les tests
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration v1 -> v2 : ajout des tables verger
        if (from < 2) {
          await m.createTable(fruitTrees);
          await m.createTable(userFruitTrees);
        }
        // Migration v2 -> v3 : événements jardin + colonnes arrosage
        if (from < 3) {
          await m.createTable(gardenEvents);
          await m.addColumn(gardenPlants, gardenPlants.sowedAt);
          await m.addColumn(
              gardenPlants, gardenPlants.wateringFrequencyDays);
        }
        // Migration v3 -> v4 : événements sans potager (plantId direct)
        if (from < 4) {
          await m.addColumn(gardenEvents, gardenEvents.plantId);
          // Recréer la table pour rendre gardenPlantId nullable
          // On drop et recrée car SQLite ne supporte pas ALTER COLUMN
          await m.deleteTable('garden_events');
          await m.createTable(gardenEvents);
        }
      },
    );
  }

  // ============================================
  // PLANTS QUERIES
  // ============================================

  Future<List<Plant>> getAllPlants() => select(plants).get();

  Future<List<Plant>> getAllPlantsSorted() {
    return (select(
      plants,
    )..orderBy([(t) => OrderingTerm.asc(t.commonName)])).get();
  }

  Future<Plant?> getPlantById(int id) {
    return (select(plants)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<Plant>> searchPlants(String query) {
    final lowerQuery = '%${query.toLowerCase()}%';
    return (select(plants)..where(
          (t) =>
              t.commonName.lower().like(lowerQuery) |
              t.latinName.lower().like(lowerQuery),
        ))
        .get();
  }

  Future<int> insertPlant(PlantsCompanion plant) {
    return into(plants).insert(plant, mode: InsertMode.insertOrReplace);
  }

  Future<bool> updatePlant(Plant plant) {
    return update(plants).replace(plant);
  }

  Future<int> deleteAllPlants() => delete(plants).go();

  Future<int> countPlants() async {
    final count = plants.id.count();
    final query = selectOnly(plants)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================
  // COMPANIONS & ANTAGONISTS QUERIES
  // ============================================

  Future<List<int>> getCompanionIds(int plantId) async {
    final results = await (select(
      plantCompanions,
    )..where((t) => t.plantId.equals(plantId))).get();
    return results.map((r) => r.companionId).toList();
  }

  Future<List<Plant>> getCompanions(int plantId) async {
    final companionIds = await getCompanionIds(plantId);
    if (companionIds.isEmpty) return [];
    return (select(plants)..where((t) => t.id.isIn(companionIds))).get();
  }

  Future<List<int>> getAntagonistIds(int plantId) async {
    final results = await (select(
      plantAntagonists,
    )..where((t) => t.plantId.equals(plantId))).get();
    return results.map((r) => r.antagonistId).toList();
  }

  Future<List<Plant>> getAntagonists(int plantId) async {
    final antagonistIds = await getAntagonistIds(plantId);
    if (antagonistIds.isEmpty) return [];
    return (select(plants)..where((t) => t.id.isIn(antagonistIds))).get();
  }

  Future<void> insertCompanion(int plantId, int companionId) {
    return into(plantCompanions).insert(
      PlantCompanionsCompanion(
        plantId: Value(plantId),
        companionId: Value(companionId),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> insertAntagonist(int plantId, int antagonistId) {
    return into(plantAntagonists).insert(
      PlantAntagonistsCompanion(
        plantId: Value(plantId),
        antagonistId: Value(antagonistId),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<int> deleteAllCompanions() => delete(plantCompanions).go();

  Future<int> deleteAllAntagonists() => delete(plantAntagonists).go();

  // ============================================
  // GARDENS QUERIES
  // ============================================

  Future<List<Garden>> getAllGardens() => select(gardens).get();

  Future<Garden?> getGardenById(int id) {
    return (select(gardens)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> createGarden(GardensCompanion garden) {
    return into(gardens).insert(garden);
  }

  Future<bool> updateGarden(Garden garden) {
    return update(gardens).replace(garden);
  }

  Future<int> deleteGarden(int id) {
    return (delete(gardens)..where((t) => t.id.equals(id))).go();
  }

  // ============================================
  // GARDEN PLANTS QUERIES
  // ============================================

  Future<List<GardenPlant>> getGardenPlants(int gardenId) {
    return (select(
      gardenPlants,
    )..where((t) => t.gardenId.equals(gardenId))).get();
  }

  Future<int> addPlantToGarden(GardenPlantsCompanion gardenPlant) {
    return into(gardenPlants).insert(gardenPlant);
  }

  Future<int> removePlantFromGarden(int id) {
    return (delete(gardenPlants)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateGardenPlantPosition(int id, int x, int y) {
    return (update(gardenPlants)..where((t) => t.id.equals(id))).write(
      GardenPlantsCompanion(gridX: Value(x), gridY: Value(y)),
    );
  }

  Future<void> updateGardenPlantSize(int id, int widthCells, int heightCells) {
    return (update(gardenPlants)..where((t) => t.id.equals(id))).write(
      GardenPlantsCompanion(
        widthCells: Value(widthCells),
        heightCells: Value(heightCells),
      ),
    );
  }

  // ============================================
  // GARDEN EVENTS QUERIES
  // ============================================

  Future<List<GardenEvent>> getEventsForGardenPlant(int gardenPlantId) {
    return (select(gardenEvents)
          ..where((t) => t.gardenPlantId.equals(gardenPlantId))
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .get();
  }

  Future<List<GardenEvent>> getAllEvents() {
    return (select(gardenEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .get();
  }

  Future<List<GardenEvent>> getEventsForMonth(int year, int month) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return (select(gardenEvents)
          ..where(
              (t) => t.eventDate.isBiggerOrEqualValue(start) & t.eventDate.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .get();
  }

  Future<GardenEvent?> getLastEventOfType(
      int gardenPlantId, String eventType) {
    return (select(gardenEvents)
          ..where((t) =>
              t.gardenPlantId.equals(gardenPlantId) &
              t.eventType.equals(eventType))
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Retourne les IDs distincts des plantes suivies (via plantId dans les events)
  Future<List<int>> getTrackedPlantIds() async {
    final events = await (select(gardenEvents)
          ..where((t) => t.plantId.isNotNull()))
        .get();
    return events.map((e) => e.plantId!).toSet().toList();
  }

  Future<int> addGardenEvent(GardenEventsCompanion event) {
    return into(gardenEvents).insert(event);
  }

  Future<int> deleteGardenEvent(int id) {
    return (delete(gardenEvents)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateGardenPlantDetails({
    required int id,
    DateTime? sowedAt,
    DateTime? plantedAt,
    int? wateringFrequencyDays,
  }) {
    return (update(gardenPlants)..where((t) => t.id.equals(id))).write(
      GardenPlantsCompanion(
        sowedAt: sowedAt != null ? Value(sowedAt) : const Value.absent(),
        plantedAt:
            plantedAt != null ? Value(plantedAt) : const Value.absent(),
        wateringFrequencyDays: wateringFrequencyDays != null
            ? Value(wateringFrequencyDays)
            : const Value.absent(),
      ),
    );
  }

  // ============================================
  // FRUIT TREES QUERIES
  // ============================================

  Future<List<FruitTree>> getAllFruitTrees() => select(fruitTrees).get();

  Future<List<FruitTree>> getAllFruitTreesSorted() {
    return (select(
      fruitTrees,
    )..orderBy([(t) => OrderingTerm.asc(t.commonName)])).get();
  }

  Future<List<FruitTree>> searchFruitTrees(String query) {
    final lowerQuery = '%${query.toLowerCase()}%';
    return (select(fruitTrees)..where(
          (t) =>
              t.commonName.lower().like(lowerQuery) |
              t.latinName.lower().like(lowerQuery),
        ))
        .get();
  }

  Future<FruitTree?> getFruitTreeById(int id) {
    return (select(
      fruitTrees,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> countFruitTrees() async {
    final count = fruitTrees.id.count();
    final query = selectOnly(fruitTrees)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> insertFruitTree(FruitTreesCompanion tree) {
    return into(fruitTrees).insert(tree, mode: InsertMode.insertOrReplace);
  }

  Future<int> deleteAllFruitTrees() => delete(fruitTrees).go();

  // ============================================
  // USER FRUIT TREES QUERIES
  // ============================================

  Future<List<UserFruitTree>> getAllUserFruitTrees() {
    return select(userFruitTrees).get();
  }

  Future<List<TypedResult>> getAllUserFruitTreesWithDetails() {
    final query = select(userFruitTrees).join([
      innerJoin(
        fruitTrees,
        fruitTrees.id.equalsExp(userFruitTrees.fruitTreeId),
      ),
    ]);
    return query.get();
  }

  Future<TypedResult?> getUserFruitTreeWithDetailsById(int id) {
    final query = select(userFruitTrees).join([
      innerJoin(
        fruitTrees,
        fruitTrees.id.equalsExp(userFruitTrees.fruitTreeId),
      ),
    ])..where(userFruitTrees.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<int> addUserFruitTree(UserFruitTreesCompanion tree) {
    return into(userFruitTrees).insert(tree);
  }

  Future<bool> updateUserFruitTree(UserFruitTree tree) {
    return update(userFruitTrees).replace(tree);
  }

  Future<void> updateUserFruitTreePartial({
    required int id,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    String? healthStatus,
    DateTime? lastPruningDate,
    DateTime? lastHarvestDate,
    double? lastYieldKg,
  }) {
    return (update(userFruitTrees)..where((t) => t.id.equals(id))).write(
      UserFruitTreesCompanion(
        nickname: nickname != null ? Value(nickname) : const Value.absent(),
        variety: variety != null ? Value(variety) : const Value.absent(),
        plantingDate: plantingDate != null
            ? Value(plantingDate)
            : const Value.absent(),
        location: location != null ? Value(location) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        healthStatus: healthStatus != null
            ? Value(healthStatus)
            : const Value.absent(),
        lastPruningDate: lastPruningDate != null
            ? Value(lastPruningDate)
            : const Value.absent(),
        lastHarvestDate: lastHarvestDate != null
            ? Value(lastHarvestDate)
            : const Value.absent(),
        lastYieldKg: lastYieldKg != null
            ? Value(lastYieldKg)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteUserFruitTree(int id) {
    return (delete(userFruitTrees)..where((t) => t.id.equals(id))).go();
  }

  Future<int> countUserFruitTrees() async {
    final count = userFruitTrees.id.count();
    final query = selectOnly(userFruitTrees)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'jardingue.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
