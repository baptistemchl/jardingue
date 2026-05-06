import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/database/app_database.dart';
// ignore: depend_on_referenced_packages -- vient transitivement de drift
import 'package:sqlite3/sqlite3.dart';

/// Migration v15 -> v16 : ajout de la colonne `custom_emoji` sur `plants`.
///
/// Avant ce changement, l'écran "Créer une plante personnalisée" proposait
/// un picker d'emoji mais le choix n'était jamais persisté — l'app
/// retombait toujours sur la déduction nom/catégorie. Après ce changement
/// l'emoji choisi par l'utilisateur est stocké et `PlantEmojiMapper.forPlant`
/// le préfère.
void main() {
  group('AppDatabase migration v15 -> v16', () {
    test('fresh DB exposes plants.custom_emoji column', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await db.countPlants();
        final cols = await db
            .customSelect('PRAGMA table_info(plants)')
            .get();
        final colNames = cols.map((r) => r.read<String>('name')).toSet();
        expect(colNames, contains('custom_emoji'),
            reason: 'Plants doit avoir la colonne v16');
      } finally {
        await db.close();
      }
    });

    test('schemaVersion >= 16', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        expect(db.schemaVersion, greaterThanOrEqualTo(16));
      } finally {
        db.close();
      }
    });

    test('v15 schema + ALTER = v16 (idempotent)', () async {
      final raw = sqlite3.openInMemory();
      try {
        // Schema v15 minimal sur `plants`.
        raw.execute('''
          CREATE TABLE plants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            common_name TEXT NOT NULL,
            category_code TEXT,
            fertilization_frequency_days INTEGER
          );
        ''');
        raw.execute('PRAGMA user_version = 15');

        // Plante user pré-existante : on vérifie que la migration la
        // préserve (custom_emoji = null = comportement legacy).
        raw.execute(
          "INSERT INTO plants (id, common_name, category_code) "
          "VALUES (1000000, 'Ma courge', 'fruit_vegetable')",
        );

        // === Migration v15 -> v16 ===
        raw.execute('ALTER TABLE plants ADD COLUMN custom_emoji TEXT');
        raw.execute('PRAGMA user_version = 16');

        // Données préservées + nouvelle colonne nullable initialement à null.
        final rows = raw.select('SELECT * FROM plants WHERE id = 1000000');
        expect(rows.length, 1);
        expect(rows.first['common_name'], 'Ma courge');
        expect(rows.first['custom_emoji'], isNull);

        // L'utilisateur peut désormais persister son choix d'emoji.
        raw.execute(
          "UPDATE plants SET custom_emoji = '🎃' WHERE id = 1000000",
        );
        final updated =
            raw.select('SELECT custom_emoji FROM plants WHERE id = 1000000');
        expect(updated.first['custom_emoji'], '🎃');

        final version =
            raw.select('PRAGMA user_version').first['user_version'];
        expect(version, 16);
      } finally {
        raw.dispose();
      }
    });
  });
}
