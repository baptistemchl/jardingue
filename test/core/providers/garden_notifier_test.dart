import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';
import 'package:jardingue/core/providers/garden_providers.dart';
import 'package:jardingue/core/services/database/app_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<int> createGarden() async {
    return db.createGarden(GardensCompanion.insert(
      name: 'Potager test',
      widthCells: Value(10),
      heightCells: Value(10),
      cellSizeCm: Value(10),
    ));
  }

  Future<int> addPlant(int gardenId) async {
    return db.addPlantToGarden(GardenPlantsCompanion.insert(
      gardenId: gardenId,
      plantId: 1,
      gridX: 2,
      gridY: 3,
      widthCells: Value(1),
      heightCells: Value(1),
      plantedAt: Value(DateTime(2025, 6, 15)),
    ));
  }

  group('GardenNotifier.removeElement', () {
    test('removes plant from database', () async {
      final gardenId = await createGarden();
      final gpId = await addPlant(gardenId);

      // Verify plant exists
      final before = await db.getGardenPlants(gardenId);
      expect(before, hasLength(1));

      // Remove via notifier
      final notifier = container.read(gardenNotifierProvider.notifier);
      await notifier.removeElement(gpId, gardenId);

      // Verify plant is gone
      final after = await db.getGardenPlants(gardenId);
      expect(after, isEmpty);
    });

    test('state returns to AsyncData after successful removal', () async {
      final gardenId = await createGarden();
      final gpId = await addPlant(gardenId);

      final notifier = container.read(gardenNotifierProvider.notifier);
      await notifier.removeElement(gpId, gardenId);

      final state = container.read(gardenNotifierProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('handles non-existent id gracefully', () async {
      final gardenId = await createGarden();

      final notifier = container.read(gardenNotifierProvider.notifier);
      // Should not throw — DELETE with no match just affects 0 rows
      await notifier.removeElement(9999, gardenId);

      final state = container.read(gardenNotifierProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('only removes targeted plant, not others', () async {
      final gardenId = await createGarden();
      final gpId1 = await addPlant(gardenId);
      final gpId2 = await db.addPlantToGarden(GardenPlantsCompanion.insert(
        gardenId: gardenId,
        plantId: 2,
        gridX: 5,
        gridY: 5,
      ));

      final notifier = container.read(gardenNotifierProvider.notifier);
      await notifier.removeElement(gpId1, gardenId);

      final remaining = await db.getGardenPlants(gardenId);
      expect(remaining, hasLength(1));
      expect(remaining.first.id, gpId2);
    });
  });

  group('GardenNotifier.createGarden + deleteGarden', () {
    test('create then delete garden', () async {
      final notifier = container.read(gardenNotifierProvider.notifier);

      final id = await notifier.createGarden(
        name: 'Mon potager',
        widthMeters: 3.0,
        heightMeters: 2.0,
      );

      expect(id, isPositive);

      await notifier.deleteGarden(id);

      final garden = await db.getGardenById(id);
      expect(garden, isNull);
    });
  });

  group('updateGardenPlantDetails via repository', () {
    test('updates plantedAt through provider', () async {
      final gardenId = await createGarden();
      final gpId = await addPlant(gardenId);

      final repo = container.read(gardenRepositoryProvider);
      final newDate = DateTime(2026, 4, 1);
      await repo.updateGardenPlantDetails(id: gpId, plantedAt: newDate);

      final plants = await db.getGardenPlants(gardenId);
      expect(plants.first.plantedAt, newDate);
    });

    test('preserves sowedAt when updating plantedAt', () async {
      final gardenId = await createGarden();
      final sowDate = DateTime(2025, 3, 1);
      final gpId = await db.addPlantToGarden(GardenPlantsCompanion.insert(
        gardenId: gardenId,
        plantId: 1,
        gridX: 0,
        gridY: 0,
        plantedAt: Value(DateTime(2025, 6, 15)),
        sowedAt: Value(sowDate),
      ));

      final repo = container.read(gardenRepositoryProvider);
      await repo.updateGardenPlantDetails(
        id: gpId,
        plantedAt: DateTime(2026, 5, 1),
      );

      final plants = await db.getGardenPlants(gardenId);
      expect(plants.first.sowedAt, sowDate);
    });
  });
}
