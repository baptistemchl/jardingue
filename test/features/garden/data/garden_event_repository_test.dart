import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/garden/data/repositories/garden_event_repository.dart';

AppDatabase _createTestDb() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late DriftGardenEventRepository repo;

  setUp(() {
    db = _createTestDb();
    repo = DriftGardenEventRepository(db);
  });

  tearDown(() => db.close());

  Future<int> createGarden() async {
    return db.into(db.gardens).insert(GardensCompanion.insert(
          name: 'Mon potager',
          widthCells: const Value(10),
          heightCells: const Value(10),
          cellSizeCm: const Value(10),
        ));
  }

  group('GardenEvents - maintenance events with gardenId only', () {
    test('insert + getEventsForMonth round-trips a maintenance event', () async {
      final gardenId = await createGarden();
      final date = DateTime(2026, 4, 10);

      final id = await repo.addEvent(GardenEventsCompanion.insert(
        gardenId: Value(gardenId),
        eventType: 'mulching',
        eventDate: date,
      ));
      expect(id, greaterThan(0));

      final events = await repo.getEventsForMonth(2026, 4);
      expect(events, hasLength(1));
      expect(events.first.gardenId, gardenId);
      expect(events.first.gardenPlantId, isNull);
      expect(events.first.plantId, isNull);
      expect(events.first.eventType, 'mulching');
    });

    test('inserts work without any garden link (loose maintenance log)',
        () async {
      final id = await repo.addEvent(GardenEventsCompanion.insert(
        eventType: 'slugControl',
        eventDate: DateTime(2026, 4, 10),
      ));
      expect(id, greaterThan(0));
      final events = await repo.getAllEvents();
      expect(events, hasLength(1));
      expect(events.first.gardenId, isNull);
      expect(events.first.gardenPlantId, isNull);
      expect(events.first.plantId, isNull);
    });

    test('deleteEvent removes the row', () async {
      final id = await repo.addEvent(GardenEventsCompanion.insert(
        eventType: 'fertilizer',
        eventDate: DateTime(2026, 4, 10),
      ));
      final deleted = await repo.deleteEvent(id);
      expect(deleted, 1);
      expect(await repo.getAllEvents(), isEmpty);
    });
  });

  group('deleteGarden cascade', () {
    test('deletes events linked via gardenId AND via gardenPlantId', () async {
      // Setup : 1 potager + 1 plante + 3 events (1 maintenance avec gardenId,
      // 1 arrosage avec gardenPlantId, 1 entretien sans potager).
      final gardenId = await createGarden();
      final plantId = await db.into(db.plants).insert(PlantsCompanion.insert(
            commonName: 'Tomate',
            categoryCode: const Value('fruit'),
            createdAt: Value(DateTime(2026, 1, 1)),
            updatedAt: Value(DateTime(2026, 1, 1)),
          ));
      final gpId = await db.addPlantToGarden(GardenPlantsCompanion.insert(
        gardenId: gardenId,
        plantId: plantId,
        gridX: 0,
        gridY: 0,
        widthCells: const Value(2),
        heightCells: const Value(2),
      ));

      // Event 1 : entretien rattache au potager (gardenId direct)
      await repo.addEvent(GardenEventsCompanion.insert(
        gardenId: Value(gardenId),
        eventType: 'mulching',
        eventDate: DateTime(2026, 4, 1),
      ));
      // Event 2 : arrosage de la plante du potager
      await repo.addEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(gpId),
        eventType: 'watering',
        eventDate: DateTime(2026, 4, 2),
      ));
      // Event 3 : entretien sans potager — NE doit PAS etre supprime
      await repo.addEvent(GardenEventsCompanion.insert(
        eventType: 'slugControl',
        eventDate: DateTime(2026, 4, 3),
      ));

      expect(await repo.getAllEvents(), hasLength(3));

      // Action : supprimer le potager. Les events 1 et 2 doivent disparaitre,
      // l'event 3 (sans lien) doit rester.
      await db.deleteGarden(gardenId);

      final remaining = await repo.getAllEvents();
      expect(remaining, hasLength(1));
      expect(remaining.first.eventType, 'slugControl');
      expect(remaining.first.gardenId, isNull);
      expect(remaining.first.gardenPlantId, isNull);
    });
  });
}
