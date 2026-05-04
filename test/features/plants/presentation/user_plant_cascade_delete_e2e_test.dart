import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/plants/data/repositories/plant_repository.dart';
import 'package:jardingue/features/plants/domain/models/user_plant_input.dart';
import 'package:jardingue/features/plants/presentation/widgets/user_plant_form_sheet.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

/// Test e2e du chemin de suppression cascade : DB Drift in-memory
/// réelle, plante user posée dans un potager + event lié, ouverture
/// du form sheet, tap supprimer, vérification du dialog enrichi puis
/// de la propagation cascade dans les tables référentes.
///
/// Ce test sert de filet de sécurité de haut niveau : il s'assure
/// que tout le tuyau (UI → repository → DB → cascade FK) reste
/// cohérent, là où les tests unitaires DB et widget couvrent
/// chacun leur étage isolément.
void main() {
  late AppDatabase db;
  late DriftPlantRepository repo;
  late int userPlantId;
  late int gardenId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftPlantRepository(db);

    // Crée une plante user "Pastèque".
    userPlantId = await repo.insertUserPlant(
      const UserPlantInput(
        commonName: 'Pastèque',
        categoryCode: 'fruit_vegetable',
        spacingBetweenPlants: 100,
        spacingBetweenRows: 150,
        sowingCalendarJson:
            '{"monthly_period":{"April":"Oui"}}',
      ),
    );

    // Crée un potager + pose la pastèque dedans + un event de suivi.
    gardenId = await db.createGarden(
      GardensCompanion.insert(
        name: 'Mon potager',
        widthCells: const Value(10),
        heightCells: const Value(10),
        cellSizeCm: const Value(30),
      ),
    );
    await db.addPlantToGarden(
      GardenPlantsCompanion.insert(
        gardenId: gardenId,
        plantId: userPlantId,
        gridX: 0,
        gridY: 0,
      ),
    );
    await db.addGardenEvent(
      GardenEventsCompanion.insert(
        plantId: Value(userPlantId),
        eventType: 'sowing',
        eventDate: DateTime(2026, 4, 15),
      ),
    );
  });

  tearDown(() => db.close());

  Widget buildApp(Plant plant) {
    return ProviderScope(
      overrides: [
        databaseInitProvider.overrideWith((_) async => 0),
        databaseProvider.overrideWithValue(db),
        plantRepositoryProvider.overrideWithValue(repo),
        allPlantsSortedProvider.overrideWith((_) async => []),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: UserPlantFormSheet(initialPlant: plant),
        ),
      ),
    );
  }

  testWidgets(
    'flow complet : suppression UI → cascade DB',
    (tester) async {
      // Viewport agrandi pour rendre le bouton supprimer + sticky bar
      // simultanément accessibles.
      await tester.binding.setSurfaceSize(const Size(800, 2200));
      addTearDown(
        () async => tester.binding.setSurfaceSize(null),
      );

      final pasteque = await db.getPlantById(userPlantId);
      expect(pasteque, isNotNull);

      await tester.pumpWidget(buildApp(pasteque!));
      await tester.pumpAndSettle();

      // Tap "Supprimer cette plante".
      final deleteBtn = find.widgetWithText(
        TextButton,
        'Supprimer cette plante',
      );
      await tester.ensureVisible(deleteBtn);
      await tester.pumpAndSettle();
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Le dialog doit afficher l'avertissement enrichi (la plante
      // est utilisée : 1 potager + 1 event).
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('figure encore dans tes plans'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Mon potager'),
        findsOneWidget,
      );
      expect(
        find.textContaining('1 événement(s)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Cette action est irréversible'),
        findsOneWidget,
      );

      // Confirmation → cascade.
      await tester.tap(
        find.widgetWithText(TextButton, 'Supprimer'),
      );
      await tester.pumpAndSettle();

      // Vérification cascade DB :
      // 1. La plante est effacée.
      expect(await db.getPlantById(userPlantId), isNull);
      // 2. Le gardenPlant est effacé (le potager lui-même reste).
      expect(await db.getGardenPlants(gardenId), isEmpty);
      expect(await db.getGardenById(gardenId), isNotNull);
      // 3. Les events liés sont effacés.
      expect(await db.getAllEvents(), isEmpty);
    },
  );
}
