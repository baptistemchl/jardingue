import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/database/app_database.dart';
// ignore: depend_on_referenced_packages -- vient transitivement de drift
import 'package:sqlite3/sqlite3.dart';

/// Verifie que la migration v14 -> v15 (fertilisation + pieges a pheromones)
/// applique correctement les changements de schema :
/// - colonne `fertilization_frequency_days` sur `plants`
/// - colonne `fertilizing_frequency_days` sur `garden_plants`
/// - nouvelle table `pheromone_traps`
///
/// On valide en deux temps :
/// 1. **DB fresh** : `onCreate` cree directement le schema v15 complet
///    → toutes les colonnes/tables doivent exister sans avoir besoin de
///    rejouer la migration.
/// 2. **Logique migration** : sur une DB sqlite simulant un schema v14, on
///    rejoue les statements de la migration et on verifie le resultat.
///    On ne peut pas easily faire migrer Drift depuis un user_version=14
///    pre-rempli (drift verrouille son etat interne), d'ou la verification
///    SQL en isolation.
void main() {
  group('AppDatabase migration v14 -> v15', () {
    test('fresh DB exposes plants.fertilization_frequency_days column',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        // Force onCreate via une requete simple
        await db.countPlants();

        // Verifie que la colonne existe via PRAGMA table_info
        final cols = await db
            .customSelect('PRAGMA table_info(plants)')
            .get();
        final colNames = cols.map((r) => r.read<String>('name')).toSet();
        expect(colNames, contains('fertilization_frequency_days'),
            reason: 'Plants doit avoir la colonne v15');
      } finally {
        await db.close();
      }
    });

    test('fresh DB exposes garden_plants.fertilizing_frequency_days column',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await db.countPlants();

        final cols = await db
            .customSelect('PRAGMA table_info(garden_plants)')
            .get();
        final colNames = cols.map((r) => r.read<String>('name')).toSet();
        expect(colNames, contains('fertilizing_frequency_days'),
            reason: 'GardenPlants doit avoir la colonne v15');
      } finally {
        await db.close();
      }
    });

    test('fresh DB creates pheromone_traps table with expected schema',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await db.countPlants();

        // La table existe ?
        final tables = await db
            .customSelect(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='pheromone_traps'")
            .get();
        expect(tables.length, 1, reason: 'Table pheromone_traps doit exister');

        // Schema attendu
        final cols = await db
            .customSelect('PRAGMA table_info(pheromone_traps)')
            .get();
        final colNames = cols.map((r) => r.read<String>('name')).toSet();
        expect(
            colNames,
            containsAll([
              'id',
              'user_fruit_tree_id',
              'trap_type',
              'installed_at',
              'lifetime_days',
              'notes',
              'created_at',
            ]),
            reason: 'Colonnes attendues sur pheromone_traps');
      } finally {
        await db.close();
      }
    });

    test('schemaVersion is 15', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        // Le bump de version doit etre fait pour que la migration s'execute
        // chez les utilisateurs existants. Si on oublie, ils restent bloques
        // a v14 sans les nouvelles colonnes.
        expect(db.schemaVersion, 15);
      } finally {
        db.close();
      }
    });

    test('v14 schema + ALTER + CREATE TABLE = v15 (logique idempotente)',
        () async {
      // Simule une DB en v14 et applique manuellement les statements
      // equivalents a la migration v14->v15. Ce test garantit que les
      // statements SQL utilises par `_safeAddColumn` / `_safeCreateTable`
      // sont compatibles avec un schema reel v14.
      final raw = sqlite3.openInMemory();
      try {
        // Schema v14 minimal (sans les colonnes/table de v15)
        raw.execute('''
          CREATE TABLE plants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            common_name TEXT NOT NULL,
            category_code TEXT
          );
        ''');
        raw.execute('''
          CREATE TABLE garden_plants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            garden_id INTEGER NOT NULL,
            plant_id INTEGER NOT NULL,
            grid_x INTEGER NOT NULL,
            grid_y INTEGER NOT NULL,
            watering_frequency_days INTEGER
          );
        ''');
        raw.execute('''
          CREATE TABLE user_fruit_trees (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fruit_tree_id INTEGER NOT NULL
          );
        ''');
        raw.execute('PRAGMA user_version = 14');

        // Donnees pre-existantes pour verifier qu'elles survivent
        raw.execute(
            "INSERT INTO plants (id, common_name, category_code) VALUES (1, 'Tomate', 'fruit_vegetable')");
        raw.execute(
            'INSERT INTO garden_plants (garden_id, plant_id, grid_x, grid_y, watering_frequency_days) VALUES (1, 1, 0, 0, 3)');

        // === Migration v14 -> v15 ===
        raw.execute(
            'ALTER TABLE plants ADD COLUMN fertilization_frequency_days INTEGER');
        raw.execute(
            'ALTER TABLE garden_plants ADD COLUMN fertilizing_frequency_days INTEGER');
        raw.execute('''
          CREATE TABLE pheromone_traps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_fruit_tree_id INTEGER NOT NULL,
            trap_type TEXT NOT NULL,
            installed_at INTEGER NOT NULL,
            lifetime_days INTEGER NOT NULL,
            notes TEXT,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (user_fruit_tree_id) REFERENCES user_fruit_trees (id)
          );
        ''');
        raw.execute('PRAGMA user_version = 15');

        // === Verifications ===
        // 1. Donnees pre-migration intactes
        final plants = raw.select('SELECT * FROM plants WHERE id = 1');
        expect(plants.length, 1);
        expect(plants.first['common_name'], 'Tomate');
        expect(plants.first['fertilization_frequency_days'], isNull,
            reason:
                'Nouvelle colonne nullable, doit etre null apres migration');

        final gardenPlants = raw.select('SELECT * FROM garden_plants');
        expect(gardenPlants.length, 1);
        expect(gardenPlants.first['watering_frequency_days'], 3,
            reason: 'L\'arrosage existant doit etre preserve');
        expect(gardenPlants.first['fertilizing_frequency_days'], isNull);

        // 2. Insertion possible dans les nouvelles colonnes
        raw.execute(
            'UPDATE plants SET fertilization_frequency_days = 21 WHERE id = 1');
        final updated = raw.select(
            'SELECT fertilization_frequency_days FROM plants WHERE id = 1');
        expect(updated.first['fertilization_frequency_days'], 21);

        // 3. Insertion possible dans pheromone_traps
        raw.execute(
            "INSERT INTO user_fruit_trees (id, fruit_tree_id) VALUES (1, 100)");
        final installedAt =
            DateTime(2026, 4, 1).millisecondsSinceEpoch ~/ 1000;
        final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        raw.execute('''
          INSERT INTO pheromone_traps (
            user_fruit_tree_id, trap_type, installed_at, lifetime_days, created_at
          ) VALUES (1, 'codlingMoth', $installedAt, 90, $createdAt)
        ''');
        final traps = raw.select('SELECT * FROM pheromone_traps');
        expect(traps.length, 1);
        expect(traps.first['trap_type'], 'codlingMoth');
        expect(traps.first['lifetime_days'], 90);

        // 4. user_version a bien ete bumpee
        final version =
            raw.select('PRAGMA user_version').first['user_version'];
        expect(version, 15);
      } finally {
        raw.dispose();
      }
    });

    test('cascade delete : suppression d\'un user_fruit_tree purge ses pieges',
        () async {
      // Verifie le comportement du `transaction { delete pheromone_traps; delete user_fruit_trees }`
      // implemente dans `deleteUserFruitTree`. Sans cascade, les pieges
      // resteraient orphelins et apparaitraient dans les rappels.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await db.countPlants(); // force init

        // Setup : 1 fruitTree catalogue + 1 user_fruit_tree + 2 pieges
        await db.customStatement('''
          INSERT INTO fruit_trees (id, common_name, emoji, created_at, updated_at)
          VALUES (100, 'Pommier', '🍎', strftime('%s','now'), strftime('%s','now'))
        ''');
        final treeId = await db.customInsert('''
          INSERT INTO user_fruit_trees (fruit_tree_id, health_status, created_at, updated_at)
          VALUES (100, 'good', strftime('%s','now'), strftime('%s','now'))
        ''');
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await db.customStatement('''
          INSERT INTO pheromone_traps
            (user_fruit_tree_id, trap_type, installed_at, lifetime_days, created_at)
          VALUES ($treeId, 'codlingMoth', $now, 90, $now)
        ''');
        await db.customStatement('''
          INSERT INTO pheromone_traps
            (user_fruit_tree_id, trap_type, installed_at, lifetime_days, created_at)
          VALUES ($treeId, 'cherryFruitFly', $now, 56, $now)
        ''');

        final beforeTraps = await db.getAllPheromoneTraps();
        expect(beforeTraps.length, 2);

        // Action : suppression cascade
        await db.deleteUserFruitTree(treeId);

        // Resultat : tous les pieges de cet arbre sont purges
        final afterTraps = await db.getAllPheromoneTraps();
        expect(afterTraps, isEmpty,
            reason: 'Les pieges doivent etre purges en cascade');
      } finally {
        await db.close();
      }
    });
  });
}
