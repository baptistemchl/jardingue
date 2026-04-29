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
    GardenAmendments,
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
  int get schemaVersion => 12;

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
          await _safeCreateTable(m, fruitTrees);
          await _safeCreateTable(m, userFruitTrees);
        }
        // Migration v2 -> v3 : colonnes arrosage sur gardenPlants
        if (from < 3) {
          await _safeAddColumn(m, gardenPlants, gardenPlants.sowedAt);
          await _safeAddColumn(
              m, gardenPlants, gardenPlants.wateringFrequencyDays);
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
          await _safeCreateTable(m, gardenEvents);
        }
        // Migration v4 -> v5 : enrichissement données (climate, toxicity, tips)
        if (from < 5) {
          await _safeAddColumn(m, plants, plants.climateAdaptation);
          await _safeAddColumn(m, plants, plants.toxicity);
          await _safeAddColumn(m, plants, plants.practicalTips);
          await _safeAddColumn(m, fruitTrees, fruitTrees.climateAdaptation);
          await _safeAddColumn(m, fruitTrees, fruitTrees.toxicity);
          await _safeAddColumn(m, fruitTrees, fruitTrees.practicalTips);
        }
        // Migration v5 -> v6 : indexes pour performances
        if (from < 6) {
          await _createIndexes();
        }
        // Migration v6 -> v7 : table selected_plants (planification)
        if (from < 7) {
          await _safeCreateTable(m, selectedPlantsTable);
        }
        // Migration v7 -> v8 : table completed_planning_tasks
        if (from < 8) {
          await _safeCreateTable(m, completedPlanningTasks);
        }
        // Migration v8 -> v9 : correction calendriers semis/plantation
        // Pas de changement de schéma, mais le flag schemaVersion=9
        // déclenche le réimport des données JSON dans PlantImportService.

        // Migration v9 -> v10 : rotation des cultures
        if (from < 10) {
          await _safeAddColumn(m, plants, plants.rotationFamily);
          await _safeAddColumn(m, gardens, gardens.year);
          await _safeAddColumn(m, gardens, gardens.previousGardenId);
          await _safeAddColumn(
              m, gardenPlants, gardenPlants.previousCropPlantId);
        }
        // Migration v10 -> v11 : calques d'amendements
        if (from < 11) {
          await _safeCreateTable(m, gardenAmendments);
        }
        // Migration v11 -> v12 : evenements d'entretien lies a un potager.
        // Ajoute la colonne gardenId pour autoriser les events sans plante
        // mais lies a un potager (paillage, anti-limaces, engrais...).
        if (from < 12) {
          await _safeAddColumn(m, gardenEvents, gardenEvents.gardenId);
        }
      },
    );
  }

  /// Ajoute une colonne en ignorant l'erreur "duplicate column name".
  ///
  /// Drift se base sur `user_version` SQLite pour decider si une migration
  /// doit s'executer. En dev (stash apply/pop, hot-reload de schema, import
  /// d'une DB plus avancee...) ou en cas de migration partielle interrompue,
  /// cette version peut etre desync avec le schema reel : la colonne existe
  /// deja mais Drift relance la migration. On rattrape l'erreur pour rester
  /// idempotent au lieu de bloquer le boot de l'app.
  Future<void> _safeAddColumn(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    try {
      await m.addColumn(table, column);
    } catch (e) {
      if (e.toString().contains('duplicate column')) return;
      rethrow;
    }
  }

  /// Variante idempotente de createTable : ignore "table already exists".
  Future<void> _safeCreateTable(Migrator m, TableInfo table) async {
    try {
      await m.createTable(table);
    } catch (e) {
      if (e.toString().contains('already exists')) return;
      rethrow;
    }
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

  Stream<List<Garden>> watchAllGardens() => select(gardens).watch();

  Future<Garden?> getGardenById(int id) {
    return (select(gardens)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Garden?> watchGardenById(int id) {
    return (select(gardens)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<int> createGarden(GardensCompanion garden) {
    return into(gardens).insert(garden);
  }

  Future<bool> updateGarden(Garden garden) {
    return update(gardens).replace(garden);
  }

  /// Mise à jour partielle d'un potager (ne touche que les champs fournis).
  Future<void> updateGardenPartial({
    required int id,
    String? name,
    int? widthCells,
    int? heightCells,
    int? cellSizeCm,
    Value<int?> year = const Value.absent(),
    Value<int?> previousGardenId = const Value.absent(),
  }) async {
    await (update(gardens)..where((t) => t.id.equals(id))).write(
      GardensCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        widthCells:
            widthCells != null ? Value(widthCells) : const Value.absent(),
        heightCells:
            heightCells != null ? Value(heightCells) : const Value.absent(),
        cellSizeCm:
            cellSizeCm != null ? Value(cellSizeCm) : const Value.absent(),
        year: year,
        previousGardenId: previousGardenId,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Supprime un potager ET ses dependances (plantes, evenements, amendements).
  ///
  /// Sans ce cascade, les events lies via gardenPlantId ou directement via
  /// gardenId restent orphelins dans la table garden_events et continuent
  /// d'apparaitre dans "Mon suivi" alors que le potager n'existe plus.
  /// On encapsule dans une transaction pour eviter les etats partiels.
  Future<int> deleteGarden(int id) async {
    return transaction(() async {
      // 1. Recuperer les ids des plantes du potager pour purger leurs events.
      final gpIds = await (selectOnly(gardenPlants)
            ..addColumns([gardenPlants.id])
            ..where(gardenPlants.gardenId.equals(id)))
          .map((r) => r.read(gardenPlants.id)!)
          .get();
      // 2. Supprimer les events lies aux plantes du potager.
      if (gpIds.isNotEmpty) {
        await (delete(gardenEvents)
              ..where((t) => t.gardenPlantId.isIn(gpIds)))
            .go();
      }
      // 3. Supprimer les events lies directement au potager (entretien).
      await (delete(gardenEvents)..where((t) => t.gardenId.equals(id))).go();
      // 4. Supprimer les amendements du potager.
      await (delete(gardenAmendments)..where((t) => t.gardenId.equals(id))).go();
      // 5. Supprimer les plantes du potager.
      await (delete(gardenPlants)..where((t) => t.gardenId.equals(id))).go();
      // 6. Enfin supprimer le potager lui-meme.
      return (delete(gardens)..where((t) => t.id.equals(id))).go();
    });
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

  Future<int> removePlantFromGarden(int id) async {
    // Supprimer les événements liés à ce gardenPlant pour éviter les orphelins
    // (visible dans "Mon suivi" sinon)
    await (delete(gardenEvents)..where((t) => t.gardenPlantId.equals(id))).go();
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
    Value<int?> previousCropPlantId = const Value.absent(),
  }) async {
    await (update(gardenPlants)..where((t) => t.id.equals(id))).write(
      GardenPlantsCompanion(
        sowedAt: sowedAt != null ? Value(sowedAt) : const Value.absent(),
        plantedAt:
            plantedAt != null ? Value(plantedAt) : const Value.absent(),
        wateringFrequencyDays: wateringFrequencyDays != null
            ? Value(wateringFrequencyDays)
            : const Value.absent(),
        previousCropPlantId: previousCropPlantId,
      ),
    );

    // Synchroniser la date de l'événement correspondant dans l'historique
    if (plantedAt != null) {
      await (update(gardenEvents)
            ..where((t) =>
                t.gardenPlantId.equals(id) &
                t.eventType.equals('planting')))
          .write(GardenEventsCompanion(eventDate: Value(plantedAt)));
    }
    if (sowedAt != null) {
      await (update(gardenEvents)
            ..where((t) =>
                t.gardenPlantId.equals(id) &
                t.eventType.equals('sowing')))
          .write(GardenEventsCompanion(eventDate: Value(sowedAt)));
    }
  }

  // ============================================
  // GARDEN AMENDMENTS QUERIES
  // ============================================

  Future<List<GardenAmendment>> getAmendmentsForGarden(int gardenId) {
    return (select(gardenAmendments)
          ..where((t) => t.gardenId.equals(gardenId))
          ..orderBy([(t) => OrderingTerm.desc(t.appliedAt)]))
        .get();
  }

  /// Agrège les amendements du potager et de ses ancêtres (via la chaîne
  /// previousGardenId) — une seule requête via CTE récursive SQLite.
  Future<List<GardenAmendment>> getAmendmentsForGardenLineage(
      int gardenId) async {
    final result = await customSelect(
      'WITH RECURSIVE lineage(id) AS ('
      '  SELECT ?1 '
      '  UNION ALL '
      '  SELECT g.previous_garden_id FROM gardens g '
      '  JOIN lineage l ON g.id = l.id '
      '  WHERE g.previous_garden_id IS NOT NULL'
      ') '
      'SELECT a.* FROM garden_amendments a '
      'WHERE a.garden_id IN (SELECT id FROM lineage) '
      'ORDER BY a.applied_at DESC',
      variables: [Variable.withInt(gardenId)],
      readsFrom: {gardenAmendments, gardens},
    ).get();
    return result.map((row) => gardenAmendments.map(row.data)).toList();
  }

  Future<int> addAmendment(GardenAmendmentsCompanion companion) {
    return into(gardenAmendments).insert(companion);
  }

  Future<int> deleteAmendment(int id) {
    return (delete(gardenAmendments)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateAmendment({
    required int id,
    String? type,
    int? gridX,
    int? gridY,
    int? widthCells,
    int? heightCells,
    DateTime? appliedAt,
    Value<String?> notes = const Value.absent(),
  }) async {
    await (update(gardenAmendments)..where((t) => t.id.equals(id))).write(
      GardenAmendmentsCompanion(
        type: type != null ? Value(type) : const Value.absent(),
        gridX: gridX != null ? Value(gridX) : const Value.absent(),
        gridY: gridY != null ? Value(gridY) : const Value.absent(),
        widthCells: widthCells != null
            ? Value(widthCells)
            : const Value.absent(),
        heightCells: heightCells != null
            ? Value(heightCells)
            : const Value.absent(),
        appliedAt:
            appliedAt != null ? Value(appliedAt) : const Value.absent(),
        notes: notes,
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

  /// Derniers événements d'arrosage par gardenPlantId.
  /// Agrégation SQL (MAX) : une ligne par plante au lieu de scanner
  /// tout l'historique d'arrosage.
  Future<Map<int, DateTime>> getLastWateringDates() async {
    final maxDate = gardenEvents.eventDate.max();
    final query = selectOnly(gardenEvents)
      ..addColumns([gardenEvents.gardenPlantId, maxDate])
      ..where(gardenEvents.eventType.equals('watering') &
          gardenEvents.gardenPlantId.isNotNull())
      ..groupBy([gardenEvents.gardenPlantId]);
    final rows = await query.get();
    final result = <int, DateTime>{};
    for (final row in rows) {
      final gpId = row.read(gardenEvents.gardenPlantId);
      final last = row.read(maxDate);
      if (gpId != null && last != null) result[gpId] = last;
    }
    return result;
  }

  // ============================================
  // REACTIVE STREAMS (Drift .watch())
  // Les écrans s'abonnent via StreamProvider ; toute mutation des
  // tables concernées est propagée automatiquement à l'UI, sans
  // invalidation manuelle.
  // ============================================

  Stream<List<TypedResult>> watchGardenPlantsWithDetails(int gardenId) {
    return (select(gardenPlants).join([
      leftOuterJoin(plants, plants.id.equalsExp(gardenPlants.plantId)),
    ])..where(gardenPlants.gardenId.equals(gardenId)))
        .watch();
  }

  Stream<List<TypedResult>> watchAllGardenPlantsWithPlantAndGarden() {
    return (select(gardenPlants).join([
      leftOuterJoin(plants, plants.id.equalsExp(gardenPlants.plantId)),
      innerJoin(gardens, gardens.id.equalsExp(gardenPlants.gardenId)),
    ])).watch();
  }

  Stream<List<GardenEvent>> watchEventsForGardenPlant(int gardenPlantId) {
    return (select(gardenEvents)
          ..where((t) => t.gardenPlantId.equals(gardenPlantId))
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .watch();
  }

  Stream<List<GardenEvent>> watchAllEvents() {
    return (select(gardenEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .watch();
  }

  Stream<GardenEvent?> watchLastEventOfType(
      int gardenPlantId, String eventType) {
    return (select(gardenEvents)
          ..where((t) =>
              t.gardenPlantId.equals(gardenPlantId) &
              t.eventType.equals(eventType))
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Stream<List<int>> watchTrackedPlantIds() {
    final query = selectOnly(gardenEvents, distinct: true)
      ..addColumns([gardenEvents.plantId])
      ..where(gardenEvents.plantId.isNotNull());
    return query
        .watch()
        .map((rows) => rows.map((r) => r.read(gardenEvents.plantId)!).toList());
  }

  Stream<List<TypedResult>> watchSelectedPlants() {
    return (select(selectedPlantsTable).join([
      innerJoin(
        plants,
        plants.id.equalsExp(selectedPlantsTable.plantId),
      ),
    ])..orderBy([
            OrderingTerm.desc(selectedPlantsTable.addedAt),
          ]))
        .watch();
  }

  Stream<List<GardenAmendment>> watchAmendmentsForGardenLineage(int gardenId) {
    return customSelect(
      'WITH RECURSIVE lineage(id) AS ('
      '  SELECT ?1 '
      '  UNION ALL '
      '  SELECT g.previous_garden_id FROM gardens g '
      '  JOIN lineage l ON g.id = l.id '
      '  WHERE g.previous_garden_id IS NOT NULL'
      ') '
      'SELECT a.* FROM garden_amendments a '
      'WHERE a.garden_id IN (SELECT id FROM lineage) '
      'ORDER BY a.applied_at DESC',
      variables: [Variable.withInt(gardenId)],
      readsFrom: {gardenAmendments, gardens},
    ).watch().map(
          (rows) =>
              rows.map((row) => gardenAmendments.map(row.data)).toList(),
        );
  }

  Stream<Map<int, DateTime>> watchLastWateringDates() {
    final maxDate = gardenEvents.eventDate.max();
    final query = selectOnly(gardenEvents)
      ..addColumns([gardenEvents.gardenPlantId, maxDate])
      ..where(gardenEvents.eventType.equals('watering') &
          gardenEvents.gardenPlantId.isNotNull())
      ..groupBy([gardenEvents.gardenPlantId]);
    return query.watch().map((rows) {
      final result = <int, DateTime>{};
      for (final row in rows) {
        final gpId = row.read(gardenEvents.gardenPlantId);
        final last = row.read(maxDate);
        if (gpId != null && last != null) result[gpId] = last;
      }
      return result;
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'jardingue.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
