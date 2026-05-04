import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/plants/data/repositories/plant_repository.dart';
import 'package:jardingue/features/plants/domain/models/user_plant_input.dart';

AppDatabase _createTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Sème quelques plantes catalogue à la main (pas via JSON), suffisant
/// pour valider le hardening de [deleteCatalogPlants] et l'isolement
/// catalogue / user.
Future<void> _seedCatalogPlants(AppDatabase db) async {
  await db.insertPlant(PlantsCompanion.insert(
    id: const Value(1),
    commonName: 'Tomate',
    categoryCode: const Value('fruit_vegetable'),
    spacingBetweenPlants: const Value(50),
    spacingBetweenRows: const Value(60),
  ));
  await db.insertPlant(PlantsCompanion.insert(
    id: const Value(2),
    commonName: 'Carotte',
    categoryCode: const Value('root'),
    spacingBetweenPlants: const Value(5),
    spacingBetweenRows: const Value(20),
  ));
}

UserPlantInput _pasteque() {
  return const UserPlantInput(
    commonName: 'Pastèque',
    categoryCode: 'fruit_vegetable',
    categoryLabel: 'Légumes-fruits',
    spacingBetweenPlants: 100,
    spacingBetweenRows: 150,
    sowingCalendarJson:
        '{"monthly_period":{"April":"Oui","May":"Oui"}}',
    plantingMinTempC: 12,
  );
}

void main() {
  late AppDatabase db;
  late DriftPlantRepository repo;

  setUp(() {
    db = _createTestDb();
    repo = DriftPlantRepository(db);
  });

  tearDown(() => db.close());

  // ============================================
  // ID ALLOCATION
  // ============================================

  group('user plant id allocation', () {
    test(
      'first user plant gets id 1_000_000',
      () async {
        await _seedCatalogPlants(db);
        final id = await repo.insertUserPlant(_pasteque());
        expect(id, AppDatabase.userPlantIdMin);
      },
    );

    test(
      'subsequent user plants increment from previous max',
      () async {
        final id1 = await repo.insertUserPlant(_pasteque());
        final id2 = await repo.insertUserPlant(
          const UserPlantInput(
            commonName: 'Manioc',
            categoryCode: 'tuber',
            spacingBetweenPlants: 80,
            spacingBetweenRows: 100,
            sowingCalendarJson:
                '{"monthly_period":{"April":"Oui"}}',
          ),
        );
        expect(id1, AppDatabase.userPlantIdMin);
        expect(id2, AppDatabase.userPlantIdMin + 1);
      },
    );
  });

  // ============================================
  // CATALOG PROTECTION
  // ============================================

  group('catalog hardening', () {
    test(
      'deleteCatalogPlants preserves user plants',
      () async {
        await _seedCatalogPlants(db);
        final userId = await repo.insertUserPlant(_pasteque());

        await db.deleteCatalogPlants();

        // Le catalogue est vide, mais la plante user existe encore.
        expect(await db.countPlants(), 1);
        expect(await db.countCatalogPlants(), 0);
        final p = await db.getPlantById(userId);
        expect(p, isNotNull);
        expect(p!.isUserModified, isTrue);
      },
    );

    test(
      'countCatalogPlants ignores user plants',
      () async {
        await _seedCatalogPlants(db);
        await repo.insertUserPlant(_pasteque());
        expect(await repo.countCatalogPlants(), 2);
      },
    );

    test(
      'deleteCatalogCompanions preserves relations involving user plants',
      () async {
        await _seedCatalogPlants(db);
        final userId = await repo.insertUserPlant(_pasteque());

        // Catalogue ↔ catalogue : doit être supprimée.
        await db.insertCompanion(1, 2);
        // Catalogue ↔ user : doit être préservée.
        await db.insertCompanion(1, userId);
        // User ↔ catalogue : doit être préservée.
        await db.insertCompanion(userId, 2);

        await db.deleteCatalogCompanions();

        final companions1 = await db.getCompanions(1);
        expect(
          companions1.map((p) => p.id),
          contains(userId),
          reason:
              'La relation tomate ↔ pastèque user doit être préservée',
        );
        // La relation 1 ↔ 2 (catalogue ↔ catalogue) a été supprimée.
        expect(
          companions1.map((p) => p.id),
          isNot(contains(2)),
          reason:
              'La relation catalogue ↔ catalogue doit être effacée',
        );
        final companionsUser = await db.getCompanions(userId);
        expect(
          companionsUser.map((p) => p.id),
          contains(2),
          reason:
              'La relation user ↔ catalogue doit être préservée',
        );
      },
    );
  });

  // ============================================
  // DELETE PROTECTION
  // ============================================

  group('user plant deletion (cascade)', () {
    test(
      'deletes a user plant when not used',
      () async {
        final id = await repo.insertUserPlant(_pasteque());
        await repo.deleteUserPlant(id);
        expect(await db.getPlantById(id), isNull);
      },
    );

    test(
      'cascades : deletes gardenPlants and gardenEvents '
      'referencing the user plant',
      () async {
        final id = await repo.insertUserPlant(_pasteque());
        final gid = await db.createGarden(
          GardensCompanion.insert(
            name: 'Mon potager',
            widthCells: const Value(10),
            heightCells: const Value(10),
            cellSizeCm: const Value(10),
          ),
        );
        final gpId = await db.addPlantToGarden(
          GardenPlantsCompanion.insert(
            gardenId: gid,
            plantId: id,
            gridX: 0,
            gridY: 0,
          ),
        );
        // Event lié via gardenPlantId.
        await db.addGardenEvent(GardenEventsCompanion.insert(
          gardenPlantId: Value(gpId),
          eventType: 'planting',
          eventDate: DateTime(2026, 5, 1),
        ));
        // Event lié directement par plantId (suivi sans potager).
        await db.addGardenEvent(GardenEventsCompanion.insert(
          plantId: Value(id),
          eventType: 'sowing',
          eventDate: DateTime(2026, 4, 15),
        ));

        await repo.deleteUserPlant(id);

        // Plante, gardenPlant et events tous effacés ; potager
        // préservé.
        expect(await db.getPlantById(id), isNull);
        expect(await db.getGardenPlants(gid), isEmpty);
        expect(await db.getAllEvents(), isEmpty);
        expect(await db.getGardenById(gid), isNotNull);
      },
    );

    test(
      'cascades : nullifies previousCropPlantId on other gardenPlants',
      () async {
        await _seedCatalogPlants(db);
        final userId = await repo.insertUserPlant(_pasteque());
        final gid = await db.createGarden(
          GardensCompanion.insert(
            name: 'Mon potager',
            widthCells: const Value(10),
            heightCells: const Value(10),
            cellSizeCm: const Value(10),
          ),
        );
        // Une plante CATALOGUE plantée cette année après la plante
        // user (rotation).
        final gpId = await db.addPlantToGarden(
          GardenPlantsCompanion.insert(
            gardenId: gid,
            plantId: 1,
            gridX: 0,
            gridY: 0,
            previousCropPlantId: Value(userId),
          ),
        );

        await repo.deleteUserPlant(userId);

        // Le gardenPlant catalogue reste en place, son
        // previousCropPlantId est juste réinitialisé.
        final remaining = await db.getGardenPlants(gid);
        expect(remaining, hasLength(1));
        expect(remaining.first.id, gpId);
        expect(remaining.first.previousCropPlantId, isNull);
      },
    );

    test(
      'erases compagne/antagoniste relations, not the catalog',
      () async {
        await _seedCatalogPlants(db);
        final id = await repo.insertUserPlant(_pasteque());
        await db.insertCompanion(id, 1);
        await db.insertAntagonist(id, 2);

        await repo.deleteUserPlant(id);

        expect(await db.getPlantById(id), isNull);
        expect(await db.getPlantById(1), isNotNull);
        expect(await db.getPlantById(2), isNotNull);
        expect(await db.getCompanions(1), isEmpty);
        expect(await db.getAntagonists(2), isEmpty);
      },
    );

    test(
      'getUserPlantUsage previews impact before deletion',
      () async {
        final id = await repo.insertUserPlant(_pasteque());
        final gid = await db.createGarden(
          GardensCompanion.insert(
            name: 'Mon potager',
            widthCells: const Value(10),
            heightCells: const Value(10),
            cellSizeCm: const Value(10),
          ),
        );
        await db.addPlantToGarden(
          GardenPlantsCompanion.insert(
            gardenId: gid,
            plantId: id,
            gridX: 0,
            gridY: 0,
          ),
        );
        await db.addGardenEvent(GardenEventsCompanion.insert(
          plantId: Value(id),
          eventType: 'watering',
          eventDate: DateTime(2026, 5, 4),
        ));

        final usage = await repo.getUserPlantUsage(id);
        expect(usage.isInUse, isTrue);
        expect(usage.gardenNames, ['Mon potager']);
        expect(usage.eventCount, 1);
      },
    );
  });
}
