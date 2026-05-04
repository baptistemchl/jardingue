import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/plants/data/repositories/plant_repository.dart';
import 'package:jardingue/features/plants/domain/models/user_plant_input.dart';
import 'package:jardingue/features/premium/data/dto/backup_dto.dart';
import 'package:jardingue/features/premium/data/repositories/backup_repository_impl.dart';
import 'package:jardingue/features/premium/domain/models/backup_data.dart';
import 'package:jardingue/features/premium/domain/models/backup_metadata.dart';

AppDatabase _createTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _seedCatalog(AppDatabase db) async {
  await db.insertPlant(PlantsCompanion.insert(
    id: const Value(1),
    commonName: 'Tomate',
    categoryCode: const Value('fruit_vegetable'),
  ));
}

UserPlantInput _pasteque() => const UserPlantInput(
      commonName: 'Pastèque',
      categoryCode: 'fruit_vegetable',
      spacingBetweenPlants: 100,
      spacingBetweenRows: 150,
      sowingCalendarJson:
          '{"monthly_period":{"April":"Oui","May":"Oui"}}',
    );

void main() {
  // ============================================
  // EXPORT/RESTORE ROUNDTRIP
  // ============================================

  group('user plant backup roundtrip', () {
    late AppDatabase db;
    late DriftPlantRepository repo;
    late BackupRepositoryImpl backup;

    setUp(() {
      db = _createTestDb();
      repo = DriftPlantRepository(db);
      backup = BackupRepositoryImpl.forTesting(db: db);
    });

    tearDown(() => db.close());

    test(
      'export then import preserves user plants and rebinds gardenPlants',
      () async {
        await _seedCatalog(db);
        // Crée 2 plantes user et place l'une d'elles dans un potager.
        final id1 = await repo.insertUserPlant(_pasteque());
        final id2 = await repo.insertUserPlant(
          const UserPlantInput(
            commonName: 'Manioc',
            categoryCode: 'tuber',
            spacingBetweenPlants: 80,
            spacingBetweenRows: 100,
            plantingCalendarJson:
                '{"monthly_period":{"May":"Oui"}}',
          ),
        );
        await db.insertCompanion(id1, 1);

        final gid = await db.createGarden(
          GardensCompanion.insert(
            name: 'Test',
            widthCells: const Value(10),
            heightCells: const Value(10),
            cellSizeCm: const Value(10),
          ),
        );
        await db.addPlantToGarden(
          GardenPlantsCompanion.insert(
            gardenId: gid,
            plantId: id1,
            gridX: 0,
            gridY: 0,
          ),
        );

        final exported = await backup.exportLocalData();

        expect(exported.userPlants, hasLength(2));
        expect(exported.userPlantCompanions, hasLength(1));
        expect(exported.metadata.userPlantCount, 2);

        // Simule un device fresh : DB neuve, on réimporte uniquement
        // le catalogue et on tente le restore.
        await db.close();
        db = _createTestDb();
        repo = DriftPlantRepository(db);
        backup = BackupRepositoryImpl.forTesting(db: db);
        await _seedCatalog(db);

        await backup.importToLocal(exported);

        // Les 2 plantes user reviennent avec leur id stable.
        final restored1 = await db.getPlantById(id1);
        final restored2 = await db.getPlantById(id2);
        expect(restored1, isNotNull);
        expect(restored1!.commonName, 'Pastèque');
        expect(restored1.isUserModified, isTrue);
        expect(restored2, isNotNull);
        expect(restored2!.commonName, 'Manioc');

        // La relation user ↔ catalogue est rebranchée.
        final companions = await db.getCompanions(id1);
        expect(companions.map((p) => p.id), contains(1));

        // Le gardenPlant pointe encore vers la pastèque (pas de FK
        // orpheline) — on vérifie en lisant la jointure.
        final gpRows =
            await db.getGardenPlantsWithDetails(gid);
        expect(gpRows, hasLength(1));
      },
    );
  });

  // ============================================
  // BACKWARD COMPAT
  // ============================================

  group('backup DTO backward compat', () {
    test(
      'fromFirestore tolerates pre-1.6 backups (no userPlants key)',
      () {
        final json = {
          'metadata': {
            'createdAt': DateTime.now().toIso8601String(),
            'gardenCount': 1,
            'plantCount': 1,
            'eventCount': 0,
            'treeCount': 0,
          },
          'gardens': [],
          'gardenPlants': [],
          'gardenEvents': [],
          'userFruitTrees': [],
          // Pas de userPlants/userPlantCompanions/Antagonists.
        };
        final data = BackupDto.fromFirestore(json);
        expect(data.userPlants, isEmpty);
        expect(data.userPlantCompanions, isEmpty);
        expect(data.userPlantAntagonists, isEmpty);
        expect(data.metadata.userPlantCount, 0);
      },
    );

    test(
      'toFirestore round-trips userPlants',
      () {
        final data = BackupData(
          metadata: BackupMetadata(
            createdAt: DateTime(2026, 5, 4),
            gardenCount: 0,
            plantCount: 0,
            eventCount: 0,
            treeCount: 0,
            userPlantCount: 1,
          ),
          gardens: const [],
          gardenPlants: const [],
          gardenEvents: const [],
          userFruitTrees: const [],
          userPlants: [
            {
              'id': 1000000,
              'commonName': 'Pastèque',
              'categoryCode': 'fruit_vegetable',
              'createdAt': '2026-05-04T00:00:00.000',
              'updatedAt': '2026-05-04T00:00:00.000',
            },
          ],
        );
        final json = BackupDto.toFirestore(data);
        final restored = BackupDto.fromFirestore(json);
        expect(restored.userPlants, hasLength(1));
        expect(
          restored.userPlants.first['commonName'],
          'Pastèque',
        );
      },
    );
  });
}
