import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'orchard_tables.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Snapshot des liens entre une plante user et le potager : permet à la
/// couche repository de décider si une suppression est sûre avant de
/// l'engager (FK non cascade, donc orphelins potentiels sinon).
class UserPlantUsageInfo {
  final List<String> gardenNames;
  final int eventCount;

  const UserPlantUsageInfo({
    required this.gardenNames,
    required this.eventCount,
  });

  bool get isInUse => gardenNames.isNotEmpty || eventCount > 0;
}

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
    // SelectedPlantsTable retiree en v13 — voir migration onUpgrade.
    CompletedPlanningTasks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Pour les tests
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 14;

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
        // Migration v6 -> v7 : table selected_plants (planification).
        // La table a ete dropee en v13 (unification des sources). Si un
        // utilisateur passe directement de v6 vers v13+, on cree quand
        // meme la table : la migration v12->v13 va la lire puis la dropper.
        if (from < 7) {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS selected_plants ('
            'plant_id INTEGER NOT NULL PRIMARY KEY, '
            'added_at INTEGER NOT NULL)',
          );
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
        // Migration v12 -> v13 : unification des sources "mes plantes".
        // La table `selected_plants` etait une troisieme source de verite
        // separee de `garden_plants` et `garden_events`. On convertit chaque
        // ligne orpheline (pas de potager, pas d'event) en event `planting`
        // avec plantId seul, puis on drop la table. Les autres lignes sont
        // implicitement preservees via leur gardenPlant ou event existant.
        if (from < 13) {
          await _migrateSelectedPlantsToEvents();
          await customStatement('DROP TABLE IF EXISTS selected_plants');
        }
        // Migration v13 -> v14 : backfill des events `planting`/`sowing`
        // pour les gardenPlants historiques. Avant ce changement, ajouter
        // une plante au potager ne creait pas systematiquement d'event,
        // donc Mon Suivi etait vide pour les plantes pre-existantes alors
        // qu'elles devraient apparaitre.
        if (from < 14) {
          await _backfillPlantingEventsForExistingGardenPlants();
        }
      },
    );
  }

  /// Pour chaque ligne de `selected_plants` qui n'est referencee ni par
  /// `garden_plants` ni par `garden_events` (= ajoutee a la planification
  /// uniquement, sans potager ni event), on cree un event `planting` avec
  /// `plantId` seul et `eventDate = addedAt`. La table est ensuite drop par
  /// le caller : pas de risque de perte, les autres lignes ont deja un
  /// gardenPlant ou event qui les rend visibles dans la planification.
  ///
  /// On verifie que la table existe avant de lire — un fresh install passe
  /// directement par onCreate sans jamais avoir cree `selected_plants`.
  Future<void> _migrateSelectedPlantsToEvents() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='selected_plants'",
    ).get();
    if (exists.isEmpty) return;

    final orphanRows = await customSelect(
      '''
      SELECT sp.plant_id AS plant_id, sp.added_at AS added_at
      FROM selected_plants sp
      WHERE NOT EXISTS (
        SELECT 1 FROM garden_plants gp WHERE gp.plant_id = sp.plant_id
      ) AND NOT EXISTS (
        SELECT 1 FROM garden_events ge WHERE ge.plant_id = sp.plant_id
      )
      ''',
    ).get();

    final now = DateTime.now();
    for (final row in orphanRows) {
      final plantId = row.read<int>('plant_id');
      // `added_at` est stocke en secondes Unix par Drift.
      final addedAtSec = row.read<int>('added_at');
      final addedAt = DateTime.fromMillisecondsSinceEpoch(
        addedAtSec * 1000,
        isUtc: false,
      );
      await into(gardenEvents).insert(GardenEventsCompanion.insert(
        plantId: Value(plantId),
        eventType: 'planting',
        eventDate: addedAt,
        createdAt: Value(now),
      ));
    }
  }

  /// Voir [backfillMissingPlantingEvents].
  Future<void> _backfillPlantingEventsForExistingGardenPlants() =>
      backfillMissingPlantingEvents();

  /// Pour chaque `garden_plant` qui n'a pas encore d'event `planting`
  /// associe, on en cree un avec `eventDate = plantedAt ?? sowedAt
  /// ?? createdAt`. Idem pour `sowing` si `sowedAt` est defini et
  /// qu'aucun event sowing n'existe encore. Garantit que toute plante
  /// posee dans un potager apparait dans Mon Suivi avec sa date reelle.
  ///
  /// Appele par la migration v13->v14 ET apres une restauration cloud
  /// (les sauvegardes anciennes ne contiennent pas systematiquement les
  /// events lies, donc les plantes restaurees seraient invisibles dans
  /// Mon Suivi sans ce backfill).
  Future<void> backfillMissingPlantingEvents() async {
    final now = DateTime.now();
    final allGp = await select(gardenPlants).get();
    for (final gp in allGp) {
      // Ignorer les zones (plantId = 0).
      if (gp.plantId == 0) continue;

      // Verifie si un event `planting` existe deja pour ce gardenPlant.
      final existingPlanting = await (select(gardenEvents)
            ..where((t) =>
                t.gardenPlantId.equals(gp.id) &
                t.eventType.equals('planting'))
            ..limit(1))
          .getSingleOrNull();

      if (existingPlanting == null) {
        final plantingDate = gp.plantedAt ?? gp.sowedAt ?? gp.createdAt;
        await into(gardenEvents).insert(GardenEventsCompanion.insert(
          gardenPlantId: Value(gp.id),
          eventType: 'planting',
          eventDate: plantingDate,
          createdAt: Value(now),
        ));
      }

      // Si la plante a un sowedAt et pas d'event sowing, on en cree un.
      if (gp.sowedAt != null) {
        final existingSowing = await (select(gardenEvents)
              ..where((t) =>
                  t.gardenPlantId.equals(gp.id) &
                  t.eventType.equals('sowing'))
              ..limit(1))
            .getSingleOrNull();
        if (existingSowing == null) {
          await into(gardenEvents).insert(GardenEventsCompanion.insert(
            gardenPlantId: Value(gp.id),
            eventType: 'sowing',
            eventDate: gp.sowedAt!,
            createdAt: Value(now),
          ));
        }
      }
    }
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

  /// Supprime uniquement les plantes catalogue (préserve les user plants).
  /// Utilisée par PlantImportService au lieu de [deleteAllPlants] pour ne
  /// jamais effacer les plantes que l'utilisateur a créées lors d'un
  /// réimport forcé du catalogue.
  Future<int> deleteCatalogPlants() =>
      (delete(plants)..where((t) => t.isUserModified.equals(false))).go();

  Future<int> countPlants() async {
    final count = plants.id.count();
    final query = selectOnly(plants)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Compte les plantes du catalogue uniquement (exclut les user plants).
  /// Source du badge "X variétés" qui doit refléter le catalogue.
  Future<int> countCatalogPlants() async {
    final count = plants.id.count();
    final query = selectOnly(plants)
      ..addColumns([count])
      ..where(plants.isUserModified.equals(false));
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

  /// Ne supprime que les paires où **les deux** plantes sont du catalogue
  /// (id < [userPlantIdMin]). Préserve toute relation impliquant au moins
  /// une user plant lors d'un réimport forcé.
  Future<int> deleteCatalogCompanions() =>
      (delete(plantCompanions)..where(
            (t) =>
                t.plantId.isSmallerThanValue(userPlantIdMin) &
                t.companionId.isSmallerThanValue(userPlantIdMin),
          ))
          .go();

  Future<int> deleteCatalogAntagonists() =>
      (delete(plantAntagonists)..where(
            (t) =>
                t.plantId.isSmallerThanValue(userPlantIdMin) &
                t.antagonistId.isSmallerThanValue(userPlantIdMin),
          ))
          .go();

  // ============================================
  // USER PLANTS (isUserModified = true)
  // ============================================

  /// IDs des plantes user démarrent à 1 000 000 pour exclure tout chevauchement
  /// avec le catalogue (max actuel ≈ 250). Garantit qu'aucun ajout futur au
  /// catalogue ne pourra écraser une plante user.
  static const int userPlantIdMin = 1000000;

  /// Prochain ID disponible pour une nouvelle plante user.
  /// Renvoie [userPlantIdMin] si aucune n'existe encore.
  Future<int> nextUserPlantId() async {
    final maxExpr = plants.id.max();
    final query = selectOnly(plants)
      ..addColumns([maxExpr])
      ..where(plants.isUserModified.equals(true));
    final result = await query.getSingle();
    final current = result.read(maxExpr);
    if (current == null) return userPlantIdMin;
    return current + 1;
  }

  /// Insère une plante user. Le caller (repository) doit avoir préassigné
  /// `id` (via [nextUserPlantId]) et positionné `isUserModified = true`.
  Future<int> insertUserPlant(PlantsCompanion data) =>
      into(plants).insert(data);

  /// Met à jour une plante user. Le where bornée à `isUserModified = true`
  /// garantit qu'aucune plante du catalogue ne peut être modifiée par
  /// erreur via cette méthode.
  Future<int> updateUserPlant(int id, PlantsCompanion data) {
    return (update(plants)..where(
          (t) => t.id.equals(id) & t.isUserModified.equals(true),
        ))
        .write(data);
  }

  /// Liste toutes les plantes user (utilisée par le backup et les tests).
  Future<List<Plant>> getAllUserPlants() {
    return (select(plants)..where((t) => t.isUserModified.equals(true))).get();
  }

  /// Renvoie un snapshot de l'utilisation d'une plante user dans le potager
  /// — noms des potagers où elle est posée + nombre d'events liés. Le
  /// repository s'en sert pour décider si une suppression est sûre.
  Future<UserPlantUsageInfo> getUserPlantUsage(int id) async {
    final gardenRows = await (select(gardenPlants).join([
      innerJoin(gardens, gardens.id.equalsExp(gardenPlants.gardenId)),
    ])..where(gardenPlants.plantId.equals(id))).get();
    final gardenNames = <String>{
      for (final r in gardenRows) r.readTable(gardens).name,
    }.toList();

    final eventCountExpr = gardenEvents.id.count();
    final eventQuery = selectOnly(gardenEvents)
      ..addColumns([eventCountExpr])
      ..where(gardenEvents.plantId.equals(id));
    final eventRow = await eventQuery.getSingle();

    return UserPlantUsageInfo(
      gardenNames: gardenNames,
      eventCount: eventRow.read(eventCountExpr) ?? 0,
    );
  }

  /// Remplace l'ensemble des compagnes d'une plante user par la liste
  /// fournie (delete + reinsert dans une transaction). Utilisé lors d'une
  /// édition pour synchroniser proprement l'état après modification.
  Future<void> replaceCompanionsForUserPlant(
    int plantId,
    List<int> companionIds,
  ) {
    return transaction(() async {
      await (delete(plantCompanions)
            ..where((t) => t.plantId.equals(plantId)))
          .go();
      for (final c in companionIds) {
        await insertCompanion(plantId, c);
      }
    });
  }

  /// Idem [replaceCompanionsForUserPlant] mais pour les antagonistes.
  Future<void> replaceAntagonistsForUserPlant(
    int plantId,
    List<int> antagonistIds,
  ) {
    return transaction(() async {
      await (delete(plantAntagonists)
            ..where((t) => t.plantId.equals(plantId)))
          .go();
      for (final a in antagonistIds) {
        await insertAntagonist(plantId, a);
      }
    });
  }

  /// Supprime une plante user **en cascade** : retire toutes les
  /// références qui la pointent (gardenPlants, gardenEvents, completed
  /// planning tasks, compagne/antagoniste, previousCropPlantId) puis
  /// la plante elle-même. Bornée à `isUserModified = true` pour ne
  /// jamais toucher au catalogue.
  ///
  /// L'UI doit afficher un avertissement préalable basé sur
  /// [getUserPlantUsage] avant d'appeler cette méthode si la plante
  /// est utilisée — la suppression est définitive et impacte le grid
  /// du potager + Mon Suivi + planning.
  Future<int> deleteUserPlant(int id) {
    return transaction(() async {
      // 1. IDs des gardenPlants liés à cette plante : on les utilise
      //    pour purger les events qui les référencent par
      //    gardenPlantId (lien indirect via la plante posée).
      final gpIds = await (selectOnly(gardenPlants)
            ..addColumns([gardenPlants.id])
            ..where(gardenPlants.plantId.equals(id)))
          .map((r) => r.read(gardenPlants.id)!)
          .get();

      if (gpIds.isNotEmpty) {
        await (delete(gardenEvents)
              ..where((t) => t.gardenPlantId.isIn(gpIds)))
            .go();
      }

      // 2. Events liés directement par plantId (suivi sans potager
      //    associé : tracked plants, planification).
      await (delete(gardenEvents)..where((t) => t.plantId.equals(id)))
          .go();

      // 3. Les gardenPlants eux-mêmes.
      await (delete(gardenPlants)..where((t) => t.plantId.equals(id)))
          .go();

      // 4. Réinitialiser previousCropPlantId là où c'était cette
      //    plante (préserve les autres lignes, on perd juste l'info
      //    de rotation pour ces poses).
      await (update(gardenPlants)
            ..where((t) => t.previousCropPlantId.equals(id)))
          .write(const GardenPlantsCompanion(
        previousCropPlantId: Value(null),
      ));

      // 5. Tâches de planification complétées qui pointaient cette
      //    plante.
      await (delete(completedPlanningTasks)
            ..where((t) => t.plantId.equals(id)))
          .go();

      // 6. Relations compagne / antagoniste (dans les deux sens).
      await (delete(plantCompanions)..where(
            (t) => t.plantId.equals(id) | t.companionId.equals(id),
          ))
          .go();
      await (delete(plantAntagonists)..where(
            (t) => t.plantId.equals(id) | t.antagonistId.equals(id),
          ))
          .go();

      // 7. La plante elle-même (bornée à isUserModified=true pour
      //    sécurité absolue : impossible de wiper du catalogue).
      return (delete(plants)..where(
            (t) => t.id.equals(id) & t.isUserModified.equals(true),
          ))
          .go();
    });
  }

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

  /// Variante catalogue-only de [getCategoryCounts]. Le badge de comptage
  /// par catégorie sur l'écran Plantes doit refléter le catalogue, pas les
  /// plantes user (sinon le total visible ne correspond plus à la promesse
  /// "X variétés").
  Future<Map<String, int>> getCatalogCategoryCounts() async {
    final countExpr = plants.id.count();
    final query = selectOnly(plants)
      ..addColumns([plants.categoryCode, countExpr])
      ..where(plants.isUserModified.equals(false))
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

  /// Stream des plantes tracees via au moins un event (avec leur date de
  /// premier event = addedAt), join avec le catalogue. Utilise par la
  /// planification pour fusionner avec les plantes posees en potager.
  Stream<List<({int plantId, String commonName, String? categoryCode, DateTime addedAt})>>
      watchTrackedPlantsWithDetails() {
    final query = selectOnly(gardenEvents)
      ..addColumns([
        gardenEvents.plantId,
        gardenEvents.eventDate.min(),
      ])
      ..where(gardenEvents.plantId.isNotNull())
      ..groupBy([gardenEvents.plantId]);

    return query.watch().asyncMap((eventRows) async {
      if (eventRows.isEmpty) return const [];
      final ids = <int>[];
      final addedAtById = <int, DateTime>{};
      for (final row in eventRows) {
        final pid = row.read(gardenEvents.plantId);
        final minDate = row.read(gardenEvents.eventDate.min());
        if (pid == null) continue;
        ids.add(pid);
        if (minDate != null) addedAtById[pid] = minDate;
      }
      final plantRows = await (select(plants)..where((t) => t.id.isIn(ids))).get();
      return plantRows.map((p) {
        return (
          plantId: p.id,
          commonName: p.commonName,
          categoryCode: p.categoryCode,
          addedAt: addedAtById[p.id] ?? DateTime.now(),
        );
      }).toList();
    });
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
