import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/database/app_database.dart';

AppDatabase _createTestDb() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

/// Valide la nouvelle source unifiee "mes plantes" : garden_plants ∪
/// garden_events.plantId distincts. La table `selected_plants` est ignoree
/// par la logique applicative depuis v13.
void main() {
  late AppDatabase db;
  setUp(() => db = _createTestDb());
  tearDown(() => db.close());

  Future<int> insertPlant(String name) {
    return db.into(db.plants).insert(PlantsCompanion.insert(
          commonName: name,
          categoryCode: const Value('fruit'),
          createdAt: Value(DateTime(2026, 1, 1)),
          updatedAt: Value(DateTime(2026, 1, 1)),
        ));
  }

  Future<int> createGarden() {
    return db.into(db.gardens).insert(GardensCompanion.insert(
          name: 'Test Garden',
          widthCells: const Value(10),
          heightCells: const Value(10),
          cellSizeCm: const Value(10),
        ));
  }

  group('watchTrackedPlantsWithDetails', () {
    test('emits plants that have at least one event with plantId', () async {
      final tomatoId = await insertPlant('Tomate');
      final eggplantId = await insertPlant('Aubergine');

      // Tomate : a un event "planting"
      await db.into(db.gardenEvents).insert(GardenEventsCompanion.insert(
            plantId: Value(tomatoId),
            eventType: 'planting',
            eventDate: DateTime(2026, 4, 1),
          ));
      // Aubergine : a un event "sowing"
      await db.into(db.gardenEvents).insert(GardenEventsCompanion.insert(
            plantId: Value(eggplantId),
            eventType: 'sowing',
            eventDate: DateTime(2026, 3, 15),
          ));
      // Event maintenance sans plantId : ne doit PAS apparaitre
      await db.into(db.gardenEvents).insert(GardenEventsCompanion.insert(
            eventType: 'mulching',
            eventDate: DateTime(2026, 4, 2),
          ));

      final tracked = await db.watchTrackedPlantsWithDetails().first;
      expect(tracked, hasLength(2));
      final ids = tracked.map((t) => t.plantId).toSet();
      expect(ids, {tomatoId, eggplantId});
    });

    test('addedAt = date du PREMIER event de la plante', () async {
      final pid = await insertPlant('Tomate');
      // Premier event en mars
      await db.into(db.gardenEvents).insert(GardenEventsCompanion.insert(
            plantId: Value(pid),
            eventType: 'sowing',
            eventDate: DateTime(2026, 3, 1),
          ));
      // Second event en avril
      await db.into(db.gardenEvents).insert(GardenEventsCompanion.insert(
            plantId: Value(pid),
            eventType: 'watering',
            eventDate: DateTime(2026, 4, 5),
          ));

      final tracked = await db.watchTrackedPlantsWithDetails().first;
      expect(tracked, hasLength(1));
      expect(tracked.first.addedAt, DateTime(2026, 3, 1));
    });
  });

  group('deleteGarden cascade keeps event-only plants', () {
    // Garantit qu'apres suppression d'un potager, les plantes qui ont AUSSI
    // un event hors-potager restent visibles dans la planification.
    test('plant in deleted garden + with off-garden event survives',
        () async {
      final gardenId = await createGarden();
      final pid = await insertPlant('Tomate');

      // Plante posee dans le potager
      final gpId = await db.addPlantToGarden(GardenPlantsCompanion.insert(
        gardenId: gardenId,
        plantId: pid,
        gridX: 0,
        gridY: 0,
        widthCells: const Value(2),
        heightCells: const Value(2),
      ));
      // Event de plantation rattache a ce gardenPlant (sera supprime)
      await db.into(db.gardenEvents).insert(GardenEventsCompanion.insert(
            gardenPlantId: Value(gpId),
            eventType: 'planting',
            eventDate: DateTime(2026, 4, 1),
          ));
      // Event hors-potager (avec plantId seul) — DOIT survivre
      await db.into(db.gardenEvents).insert(GardenEventsCompanion.insert(
            plantId: Value(pid),
            eventType: 'sowing',
            eventDate: DateTime(2026, 3, 15),
          ));

      // Suppression du potager (cascade)
      await db.deleteGarden(gardenId);

      // La plante reste trackee via l'event hors-potager
      final tracked = await db.watchTrackedPlantsWithDetails().first;
      expect(tracked, hasLength(1));
      expect(tracked.first.plantId, pid);
    });
  });
}
