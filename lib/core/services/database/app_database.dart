import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Plants, PlantCompanions, PlantAntagonists, Gardens, GardenPlants])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Pour les tests
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Futures migrations ici
      },
    );
  }

  // ============================================
  // PLANTS QUERIES
  // ============================================

  /// Récupère toutes les plantes
  Future<List<Plant>> getAllPlants() => select(plants).get();

  /// Récupère toutes les plantes triées par nom
  Future<List<Plant>> getAllPlantsSorted() {
    return (select(plants)..orderBy([(t) => OrderingTerm.asc(t.commonName)])).get();
  }

  /// Récupère une plante par son ID
  Future<Plant?> getPlantById(int id) {
    return (select(plants)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Recherche de plantes par nom
  Future<List<Plant>> searchPlants(String query) {
    final lowerQuery = '%${query.toLowerCase()}%';
    return (select(plants)
          ..where((t) => t.commonName.lower().like(lowerQuery) | t.latinName.lower().like(lowerQuery)))
        .get();
  }

  /// Insère une plante
  Future<int> insertPlant(PlantsCompanion plant) {
    return into(plants).insert(plant, mode: InsertMode.insertOrReplace);
  }

  /// Met à jour une plante
  Future<bool> updatePlant(Plant plant) {
    return update(plants).replace(plant);
  }

  /// Supprime toutes les plantes (pour réimport)
  Future<int> deleteAllPlants() => delete(plants).go();

  /// Compte le nombre de plantes
  Future<int> countPlants() async {
    final count = plants.id.count();
    final query = selectOnly(plants)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================
  // COMPANIONS & ANTAGONISTS QUERIES
  // ============================================

  /// Récupère les IDs des plantes compagnes
  Future<List<int>> getCompanionIds(int plantId) async {
    final query = select(plantCompanions)..where((t) => t.plantId.equals(plantId));
    final results = await query.get();
    return results.map((r) => r.companionId).toList();
  }

  /// Récupère les plantes compagnes
  Future<List<Plant>> getCompanions(int plantId) async {
    final companionIds = await getCompanionIds(plantId);
    if (companionIds.isEmpty) return [];
    return (select(plants)..where((t) => t.id.isIn(companionIds))).get();
  }

  /// Récupère les IDs des plantes antagonistes
  Future<List<int>> getAntagonistIds(int plantId) async {
    final query = select(plantAntagonists)..where((t) => t.plantId.equals(plantId));
    final results = await query.get();
    return results.map((r) => r.antagonistId).toList();
  }

  /// Récupère les plantes antagonistes
  Future<List<Plant>> getAntagonists(int plantId) async {
    final antagonistIds = await getAntagonistIds(plantId);
    if (antagonistIds.isEmpty) return [];
    return (select(plants)..where((t) => t.id.isIn(antagonistIds))).get();
  }

  /// Insère une relation compagnon
  Future<void> insertCompanion(int plantId, int companionId) {
    return into(plantCompanions).insert(
      PlantCompanionsCompanion(
        plantId: Value(plantId),
        companionId: Value(companionId),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Insère une relation antagoniste
  Future<void> insertAntagonist(int plantId, int antagonistId) {
    return into(plantAntagonists).insert(
      PlantAntagonistsCompanion(
        plantId: Value(plantId),
        antagonistId: Value(antagonistId),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Supprime toutes les relations compagnons
  Future<int> deleteAllCompanions() => delete(plantCompanions).go();

  /// Supprime toutes les relations antagonistes
  Future<int> deleteAllAntagonists() => delete(plantAntagonists).go();

  // ============================================
  // GARDENS QUERIES
  // ============================================

  /// Récupère tous les potagers
  Future<List<Garden>> getAllGardens() => select(gardens).get();

  /// Récupère un potager par son ID
  Future<Garden?> getGardenById(int id) {
    return (select(gardens)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Crée un nouveau potager
  Future<int> createGarden(GardensCompanion garden) {
    return into(gardens).insert(garden);
  }

  /// Met à jour un potager
  Future<bool> updateGarden(Garden garden) {
    return update(gardens).replace(garden);
  }

  /// Supprime un potager
  Future<int> deleteGarden(int id) {
    return (delete(gardens)..where((t) => t.id.equals(id))).go();
  }

  // ============================================
  // GARDEN PLANTS QUERIES
  // ============================================

  /// Récupère les plantes d'un potager
  Future<List<GardenPlant>> getGardenPlants(int gardenId) {
    return (select(gardenPlants)..where((t) => t.gardenId.equals(gardenId))).get();
  }

  /// Ajoute une plante à un potager
  Future<int> addPlantToGarden(GardenPlantsCompanion gardenPlant) {
    return into(gardenPlants).insert(gardenPlant);
  }

  /// Supprime une plante d'un potager
  Future<int> removePlantFromGarden(int id) {
    return (delete(gardenPlants)..where((t) => t.id.equals(id))).go();
  }

  /// Met à jour la position d'une plante dans un potager
  Future<void> updateGardenPlantPosition(int id, int x, int y) {
    return (update(gardenPlants)..where((t) => t.id.equals(id))).write(
      GardenPlantsCompanion(gridX: Value(x), gridY: Value(y)),
    );
  }
}

/// Ouvre la connexion à la base de données
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'jardingue.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
