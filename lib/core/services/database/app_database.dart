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
    SelectedPlantsTable,
    CompletedPlanningTasks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Pour les tests
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createIndexes();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration v1 -> v2 : ajout des tables verger
        if (from < 2) {
          await m.createTable(fruitTrees);
          await m.createTable(userFruitTrees);
        }
        // Migration v2 -> v3 : colonnes arrosage sur gardenPlants
        if (from < 3) {
          await m.addColumn(gardenPlants, gardenPlants.sowedAt);
          await m.addColumn(
              gardenPlants, gardenPlants.wateringFrequencyDays);
        }
        // Migration v3 -> v4 : table gardenEvents avec plantId nullable
        // Pour les utilisateurs venant de v2 ou v1, la table n'existe pas
        // encore, donc on la crée directement avec le schéma final.
        // Pour ceux venant de v3, on drop l'ancienne (gardenPlantId NOT NULL)
        // et on recrée avec le nouveau schéma (gardenPlantId nullable + plantId).
        if (from < 4) {
          if (from >= 3) {
            // L'ancienne table existe avec gardenPlantId NOT NULL
            await m.deleteTable('garden_events');
          }
          await m.createTable(gardenEvents);
        }
        // Migration v4 -> v5 : enrichissement données (climate, toxicity, tips)
        if (from < 5) {
          await m.addColumn(plants, plants.climateAdaptation);
          await m.addColumn(plants, plants.toxicity);
          await m.addColumn(plants, plants.practicalTips);
          await m.addColumn(fruitTrees, fruitTrees.climateAdaptation);
          await m.addColumn(fruitTrees, fruitTrees.toxicity);
          await m.addColumn(fruitTrees, fruitTrees.practicalTips);
        }
        // Migration v5 -> v6 : indexes pour performances
        if (from < 6) {
          await _createIndexes();
        }
        // Migration v6 -> v7 : table selected_plants (planification)
        if (from < 7) {
          await m.createTable(selectedPlantsTable);
        }
        // Migration v7 -> v8 : table completed_planning_tasks
        if (from < 8) {
          await m.createTable(completedPlanningTasks);
        }
      },
    );
  }

  Future<void> _createIndexes() async {
    const statements = [
      // Plants : recherche et filtres
      'CREATE INDEX IF NOT EXISTS idx_plants_common_name ON plants(common_name)',
      'CREATE INDEX IF NOT EXISTS idx_plants_category_code ON plants(category_code)',
      // GardenPlants : FK lookups
      'CREATE INDEX IF NOT EXISTS idx_garden_plants_garden_id ON garden_plants(garden_id)',
      'CREATE INDEX IF NOT EXISTS idx_garden_plants_plant_id ON garden_plants(plant_id)',
      // GardenEvents : requêtes composites fréquentes
      'CREATE INDEX IF NOT EXISTS idx_garden_events_gp_type_date ON garden_events(garden_plant_id, event_type, event_date)',
      'CREATE INDEX IF NOT EXISTS idx_garden_events_plant_id ON garden_events(plant_id)',
      'CREATE INDEX IF NOT EXISTS idx_garden_events_date ON garden_events(event_date)',
      // FruitTrees : recherche et filtres
      'CREATE INDEX IF NOT EXISTS idx_fruit_trees_common_name ON fruit_trees(common_name)',
      'CREATE INDEX IF NOT EXISTS idx_fruit_trees_category ON fruit_trees(category)',
      // UserFruitTrees : FK
      'CREATE INDEX IF NOT EXISTS idx_user_fruit_trees_fruit_tree_id ON user_fruit_trees(fruit_tree_id)',
    ];
    for (final sql in statements) {
      await customStatement(sql);
    }
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

  Future<List<Plant>> getCompanions(int plantId) {
    final companion = alias(plants, 'c');
    return (select(plantCompanions).join([
      innerJoin(companion, companion.id.equalsExp(plantCompanions.companionId)),
    ])..where(plantCompanions.plantId.equals(plantId)))
        .map((row) => row.readTable(companion))
        .get();
  }

  Future<List<int>> getAntagonistIds(int plantId) async {
    final results = await (select(
      plantAntagonists,
    )..where((t) => t.plantId.equals(plantId))).get();
    return results.map((r) => r.antagonistId).toList();
  }

  Future<List<Plant>> getAntagonists(int plantId) {
    final antagonist = alias(plants, 'a');
    return (select(plantAntagonists).join([
      innerJoin(
          antagonist, antagonist.id.equalsExp(plantAntagonists.antagonistId)),
    ])..where(plantAntagonists.plantId.equals(plantId)))
        .map((row) => row.readTable(antagonist))
        .get();
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
    final query = selectOnly(gardenEvents, distinct: true)
      ..addColumns([gardenEvents.plantId])
      ..where(gardenEvents.plantId.isNotNull());
    final results = await query.get();
    return results.map((row) => row.read(gardenEvents.plantId)!).toList();
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
  // SELECTED PLANTS QUERIES (PLANNING)
  // ============================================

  Future<List<TypedResult>> getSelectedPlants() {
    return (select(selectedPlantsTable).join([
      innerJoin(
        plants,
        plants.id.equalsExp(
          selectedPlantsTable.plantId,
        ),
      ),
    ])..orderBy([
        OrderingTerm.desc(
          selectedPlantsTable.addedAt,
        ),
      ]))
        .get();
  }

  Future<int> insertSelectedPlant(int plantId) {
    return into(selectedPlantsTable).insert(
      SelectedPlantsTableCompanion(
        plantId: Value(plantId),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<int> deleteSelectedPlant(int plantId) {
    return (delete(selectedPlantsTable)
          ..where(
            (t) => t.plantId.equals(plantId),
          ))
        .go();
  }

  Future<List<int>> getSelectedPlantIds() async {
    final rows = await (select(selectedPlantsTable)
          ..orderBy([
            (t) => OrderingTerm.desc(t.addedAt),
          ]))
        .get();
    return rows
        .map((r) => r.plantId)
        .toList();
  }

  // ============================================
  // COMPLETED PLANNING TASKS QUERIES
  // ============================================

  Future<Set<String>> getCompletedTaskKeys({
    required int year,
  }) async {
    final rows = await (select(
      completedPlanningTasks,
    )..where((t) => t.year.equals(year)))
        .get();
    return rows
        .map((r) => '${r.taskKey}_${r.month}')
        .toSet();
  }

  Future<void> togglePlanningTask({
    required String taskKey,
    required int year,
    required int month,
    int? plantId,
  }) async {
    final existing = await (select(
      completedPlanningTasks,
    )..where(
            (t) =>
                t.taskKey.equals(taskKey) &
                t.year.equals(year) &
                t.month.equals(month),
          ))
        .getSingleOrNull();

    if (existing != null) {
      await (delete(completedPlanningTasks)
            ..where(
              (t) => t.id.equals(existing.id),
            ))
          .go();
    } else {
      await into(completedPlanningTasks).insert(
        CompletedPlanningTasksCompanion(
          taskKey: Value(taskKey),
          plantId: Value(plantId),
          year: Value(year),
          month: Value(month),
        ),
      );
    }
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

  // ============================================
  // OPTIMIZED QUERIES (v6)
  // ============================================

  /// Requête filtrée côté SQL (évite le chargement + filtrage en mémoire)
  Future<List<Plant>> getFilteredPlants({
    String? searchQuery,
    String? categoryCode,
    String? sunExposureContains,
  }) {
    final q = select(plants);
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lq = '%${searchQuery.toLowerCase()}%';
      q.where(
        (t) =>
            t.commonName.lower().like(lq) | t.latinName.lower().like(lq),
      );
    }
    if (categoryCode != null) {
      q.where((t) => t.categoryCode.equals(categoryCode));
    }
    if (sunExposureContains != null) {
      q.where(
        (t) => t.sunExposure.lower().like('%$sunExposureContains%'),
      );
    }
    q.orderBy([(t) => OrderingTerm.asc(t.commonName)]);
    return q.get();
  }

  /// Comptage par catégorie via SQL GROUP BY
  Future<Map<String, int>> getCategoryCounts() async {
    final countExpr = plants.id.count();
    final query = selectOnly(plants)
      ..addColumns([plants.categoryCode, countExpr])
      ..groupBy([plants.categoryCode]);
    final results = await query.get();
    return {
      for (final row in results)
        (row.read(plants.categoryCode) ?? 'unknown'):
            (row.read(countExpr) ?? 0),
    };
  }

  /// Requête filtrée côté SQL pour les arbres fruitiers
  Future<List<FruitTree>> getFilteredFruitTrees({
    String? searchQuery,
    String? categoryCode,
    bool? selfFertileOnly,
    bool? containerSuitableOnly,
  }) {
    final q = select(fruitTrees);
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lq = '%${searchQuery.toLowerCase()}%';
      q.where(
        (t) =>
            t.commonName.lower().like(lq) | t.latinName.lower().like(lq),
      );
    }
    if (categoryCode != null) {
      q.where((t) => t.category.equals(categoryCode));
    }
    if (selfFertileOnly == true) {
      q.where((t) => t.selfFertile.equals(true));
    }
    if (containerSuitableOnly == true) {
      q.where((t) => t.containerSuitable.equals(true));
    }
    q.orderBy([(t) => OrderingTerm.asc(t.commonName)]);
    return q.get();
  }

  /// Garden plants avec détails plante via JOIN (élimine le N+1)
  Future<List<TypedResult>> getGardenPlantsWithDetails(int gardenId) {
    return (select(gardenPlants).join([
      leftOuterJoin(plants, plants.id.equalsExp(gardenPlants.plantId)),
    ])..where(gardenPlants.gardenId.equals(gardenId)))
        .get();
  }

  /// Récupère plusieurs plantes par IDs en une seule requête
  Future<List<Plant>> getPlantsByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value([]);
    return (select(plants)..where((t) => t.id.isIn(ids))).get();
  }

  /// Toutes les plantes de tous les jardins avec détails (pour watering bulk)
  Future<List<TypedResult>> getAllGardenPlantsWithPlantAndGarden() {
    return (select(gardenPlants).join([
      leftOuterJoin(plants, plants.id.equalsExp(gardenPlants.plantId)),
      innerJoin(gardens, gardens.id.equalsExp(gardenPlants.gardenId)),
    ])).get();
  }

  /// Derniers événements d'arrosage par gardenPlantId (1 query au lieu de N)
  Future<Map<int, DateTime>> getLastWateringDates() async {
    final events = await (select(gardenEvents)
          ..where((t) =>
              t.eventType.equals('watering') &
              t.gardenPlantId.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .get();
    final result = <int, DateTime>{};
    for (final event in events) {
      result.putIfAbsent(event.gardenPlantId!, () => event.eventDate);
    }
    return result;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'jardingue.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
