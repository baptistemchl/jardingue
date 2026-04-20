import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/garden/data/repositories/garden_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

/// In-memory database for testing.
AppDatabase _createTestDb() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late DriftGardenRepository repo;

  setUp(() {
    db = _createTestDb();
    repo = DriftGardenRepository(db);
  });

  tearDown(() => db.close());

  // ── Helpers ──

  Future<int> createGarden() async {
    return repo.createGarden(GardensCompanion.insert(
      name: 'Test Garden',
      widthCells: Value(10),
      heightCells: Value(10),
      cellSizeCm: Value(10),
    ));
  }

  Future<int> addPlant(int gardenId, {DateTime? plantedAt, DateTime? sowedAt}) async {
    return db.addPlantToGarden(GardenPlantsCompanion.insert(
      gardenId: gardenId,
      plantId: 1,
      gridX: 0,
      gridY: 0,
      widthCells: Value(2),
      heightCells: Value(2),
      plantedAt: Value(plantedAt ?? DateTime(2025, 6, 15)),
      sowedAt: Value(sowedAt),
    ));
  }

  // ============================================
  // REMOVE PLANT FROM GARDEN
  // ============================================

  group('removePlantFromGarden', () {
    test('deletes the garden plant row', () async {
      final gardenId = await createGarden();
      final gpId = await addPlant(gardenId);

      final before = await repo.getGardenPlants(gardenId);
      expect(before, hasLength(1));

      final deleted = await repo.removePlantFromGarden(gpId);
      expect(deleted, 1);

      final after = await repo.getGardenPlants(gardenId);
      expect(after, isEmpty);
    });

    test('returns 0 when id does not exist', () async {
      final deleted = await repo.removePlantFromGarden(9999);
      expect(deleted, 0);
    });

    test('only deletes the targeted plant', () async {
      final gardenId = await createGarden();
      final gpId1 = await addPlant(gardenId);
      final gpId2 = await db.addPlantToGarden(GardenPlantsCompanion.insert(
        gardenId: gardenId,
        plantId: 2,
        gridX: 3,
        gridY: 3,
        widthCells: Value(1),
        heightCells: Value(1),
      ));

      await repo.removePlantFromGarden(gpId1);

      final remaining = await repo.getGardenPlants(gardenId);
      expect(remaining, hasLength(1));
      expect(remaining.first.id, gpId2);
    });
  });

  // ============================================
  // UPDATE GARDEN PLANT DETAILS (DATE)
  // ============================================

  group('updateGardenPlantDetails', () {
    test('updates plantedAt date', () async {
      final gardenId = await createGarden();
      final gpId = await addPlant(gardenId, plantedAt: DateTime(2025, 6, 15));

      final newDate = DateTime(2026, 3, 20);
      await repo.updateGardenPlantDetails(id: gpId, plantedAt: newDate);

      final plants = await repo.getGardenPlants(gardenId);
      expect(plants.first.plantedAt, newDate);
    });

    test('updates sowedAt date', () async {
      final gardenId = await createGarden();
      final gpId = await addPlant(gardenId, sowedAt: DateTime(2025, 3, 1));

      final newDate = DateTime(2026, 2, 10);
      await repo.updateGardenPlantDetails(id: gpId, sowedAt: newDate);

      final plants = await repo.getGardenPlants(gardenId);
      expect(plants.first.sowedAt, newDate);
    });

    test('does not overwrite other fields when updating one', () async {
      final gardenId = await createGarden();
      final originalPlanted = DateTime(2025, 6, 15);
      final originalSowed = DateTime(2025, 3, 1);
      final gpId = await addPlant(
        gardenId,
        plantedAt: originalPlanted,
        sowedAt: originalSowed,
      );

      // Update only plantedAt
      await repo.updateGardenPlantDetails(
        id: gpId,
        plantedAt: DateTime(2026, 4, 1),
      );

      final plants = await repo.getGardenPlants(gardenId);
      final gp = plants.first;
      expect(gp.plantedAt, DateTime(2026, 4, 1));
      expect(gp.sowedAt, originalSowed, reason: 'sowedAt should not change');
    });

    test('updates wateringFrequencyDays', () async {
      final gardenId = await createGarden();
      final gpId = await addPlant(gardenId);

      await repo.updateGardenPlantDetails(id: gpId, wateringFrequencyDays: 3);

      final plants = await repo.getGardenPlants(gardenId);
      expect(plants.first.wateringFrequencyDays, 3);
    });

    test('no-op when all parameters are null', () async {
      final gardenId = await createGarden();
      final originalDate = DateTime(2025, 6, 15);
      final gpId = await addPlant(gardenId, plantedAt: originalDate);

      // Call with no actual updates
      await repo.updateGardenPlantDetails(id: gpId);

      final plants = await repo.getGardenPlants(gardenId);
      expect(plants.first.plantedAt, originalDate);
    });

    test('syncs planting event date in history', () async {
      final gardenId = await createGarden();
      final originalDate = DateTime(2025, 6, 15);
      final gpId = await addPlant(gardenId, plantedAt: originalDate);

      // Create a planting event (like addPlantToGarden does)
      await db.addGardenEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gpId),
        eventType: 'planting',
        eventDate: originalDate,
      ));

      // Update the planting date
      final newDate = DateTime(2026, 4, 1);
      await repo.updateGardenPlantDetails(id: gpId, plantedAt: newDate);

      // The event date should be synced
      final events = await db.getEventsForGardenPlant(gpId);
      final plantingEvent = events.firstWhere((e) => e.eventType == 'planting');
      expect(plantingEvent.eventDate, newDate);
    });

    test('syncs sowing event date in history', () async {
      final gardenId = await createGarden();
      final originalSow = DateTime(2025, 3, 1);
      final gpId = await addPlant(gardenId, sowedAt: originalSow);

      await db.addGardenEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gpId),
        eventType: 'sowing',
        eventDate: originalSow,
      ));

      final newDate = DateTime(2026, 2, 15);
      await repo.updateGardenPlantDetails(id: gpId, sowedAt: newDate);

      final events = await db.getEventsForGardenPlant(gpId);
      final sowingEvent = events.firstWhere((e) => e.eventType == 'sowing');
      expect(sowingEvent.eventDate, newDate);
    });

    test('does not affect other event types when updating plantedAt', () async {
      final gardenId = await createGarden();
      final gpId = await addPlant(gardenId, plantedAt: DateTime(2025, 6, 15));

      final wateringDate = DateTime(2025, 7, 1);
      await db.addGardenEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gpId),
        eventType: 'planting',
        eventDate: DateTime(2025, 6, 15),
      ));
      await db.addGardenEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gpId),
        eventType: 'watering',
        eventDate: wateringDate,
      ));

      await repo.updateGardenPlantDetails(
        id: gpId,
        plantedAt: DateTime(2026, 5, 1),
      );

      final events = await db.getEventsForGardenPlant(gpId);
      final watering = events.firstWhere((e) => e.eventType == 'watering');
      expect(watering.eventDate, wateringDate, reason: 'watering date should not change');
    });
  });

  // ============================================
  // GARDEN PLANTS WITH DETAILS
  // ============================================

  group('getGardenPlantsWithDetails', () {
    test('returns plants with join data', () async {
      final gardenId = await createGarden();
      await addPlant(gardenId);

      final details = await repo.getGardenPlantsWithDetails(gardenId);
      expect(details, hasLength(1));
      expect(details.first.gardenPlant.gardenId, gardenId);
    });

    test('returns empty list after all plants removed', () async {
      final gardenId = await createGarden();
      final gpId = await addPlant(gardenId);

      await repo.removePlantFromGarden(gpId);

      final details = await repo.getGardenPlantsWithDetails(gardenId);
      expect(details, isEmpty);
    });
  });

  // ============================================
  // CASCADE DELETE: EVENTS CLEANED ON PLANT REMOVAL
  // ============================================

  group('removePlantFromGarden cascade', () {
    test('deletes associated garden events', () async {
      final gardenId = await createGarden();
      final gpId = await addPlant(gardenId);

      // Add events linked to this garden plant
      await db.addGardenEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gpId),
        eventType: 'watering',
        eventDate: DateTime(2025, 7, 1),
      ));
      await db.addGardenEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gpId),
        eventType: 'harvest',
        eventDate: DateTime(2025, 8, 1),
      ));

      // Verify events exist
      final eventsBefore = await db.getEventsForGardenPlant(gpId);
      expect(eventsBefore, hasLength(2));

      // Remove plant — should cascade delete events
      await repo.removePlantFromGarden(gpId);

      // Events should be gone
      final eventsAfter = await db.getEventsForGardenPlant(gpId);
      expect(eventsAfter, isEmpty, reason: 'Events should be cascade deleted');
    });

    test('does not delete events of other plants', () async {
      final gardenId = await createGarden();
      final gpId1 = await addPlant(gardenId);
      final gpId2 = await db.addPlantToGarden(GardenPlantsCompanion.insert(
        gardenId: gardenId,
        plantId: 2,
        gridX: 5,
        gridY: 5,
      ));

      // Add events for both plants
      await db.addGardenEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gpId1),
        eventType: 'watering',
        eventDate: DateTime(2025, 7, 1),
      ));
      await db.addGardenEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gpId2),
        eventType: 'watering',
        eventDate: DateTime(2025, 7, 2),
      ));

      // Remove only plant 1
      await repo.removePlantFromGarden(gpId1);

      // Plant 2 events should remain
      final events2 = await db.getEventsForGardenPlant(gpId2);
      expect(events2, hasLength(1));
    });

    test('events without gardenPlantId are not affected', () async {
      final gardenId = await createGarden();
      final gpId = await addPlant(gardenId);

      // Add event linked to gardenPlant
      await db.addGardenEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gpId),
        eventType: 'watering',
        eventDate: DateTime(2025, 7, 1),
      ));

      // Add standalone event (plantId only, no gardenPlantId)
      await db.addGardenEvent(GardenEventsCompanion.insert(
        plantId: Value(1),
        eventType: 'harvest',
        eventDate: DateTime(2025, 8, 1),
      ));

      await repo.removePlantFromGarden(gpId);

      // Standalone event should remain
      final allEvents = await (db.select(db.gardenEvents)).get();
      expect(allEvents, hasLength(1));
      expect(allEvents.first.eventType, 'harvest');
    });
  });
}
