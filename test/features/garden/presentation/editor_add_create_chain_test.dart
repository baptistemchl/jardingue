import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/garden/presentation/widgets/editor/editor_add_element_sheet.dart';
import 'package:jardingue/features/plants/presentation/widgets/user_plant_form_sheet.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

Garden _fakeGarden() => Garden(
      id: 1,
      name: 'Test',
      widthCells: 10,
      heightCells: 10,
      cellSizeCm: 30,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

/// Notifier stable utilisé en test : `clearFilters()` est rendu
/// no-op pour que la `Future.microtask` postée par le widget en
/// `dispose` ne touche pas un provider déjà disposé (Riverpod 3.x
/// lève sinon une "Cannot use ref … was disposed" en fin de test).
class _StableFilterNotifier extends PlantsFilterNotifier {
  @override
  PlantsFilterState build() => const PlantsFilterState();

  @override
  void clearFilters() {
    // No-op : ce notifier n'a pas de raison d'être réinitialisé en
    // test, et on évite d'altérer l'état après teardown du scope.
  }
}

Widget _buildApp({
  required Widget child,
  List<Plant> plants = const [],
}) {
  return ProviderScope(
    overrides: [
      databaseInitProvider.overrideWith((_) async => 0),
      filteredPlantsProvider.overrideWith((_) async => plants),
      allPlantsSortedProvider.overrideWith((_) async => plants),
      plantsFilterProvider.overrideWith(_StableFilterNotifier.new),
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
      home: Scaffold(body: child),
    ),
  );
}

EditorAddElementSheet _buildSheet() {
  return EditorAddElementSheet(
    garden: _fakeGarden(),
    maxWidthM: 3.0,
    maxHeightM: 3.0,
    onPlantAdded: (id, w, h, {sowedAt, plantedAt,
        wateringFrequencyDays, previousCropPlantId}) {},
    onZoneAdded: (_, _, _) {},
    onAmendmentAdded: (_, _, _, _) {},
  );
}

void main() {
  group('EditorAddElementSheet — création de plante personnalisée', () {
    testWidgets(
      'à l\'étape 1 (sélection plante), la tuile "Créer une plante '
      'personnalisée" est visible au-dessus de la liste',
      (tester) async {
        // Viewport agrandi : la sheet a une hauteur dynamique
        // calculée sur la taille d'écran ; petit viewport = sheet
        // étriquée.
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(
          () async => tester.binding.setSurfaceSize(null),
        );

        await tester.pumpWidget(_buildApp(child: _buildSheet()));
        await tester.pumpAndSettle();

        // Étape 0 : on tape sur "Ajouter une plante" pour passer à
        // la sélection de plantes (étape 1).
        expect(find.text('Ajouter une plante'), findsOneWidget);
        await tester.tap(find.text('Ajouter une plante'));
        await tester.pumpAndSettle();

        // Étape 1 : la tuile primaire "Créer une plante
        // personnalisée" doit être présente, AVANT la liste des
        // plantes (donc même quand la liste est vide ou non).
        expect(
          find.text('Créer une plante personnalisée'),
          findsOneWidget,
        );
        expect(
          find.text('Pas dans la liste ? Ajoute-la'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tap sur la tuile ouvre UserPlantFormSheet',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(
          () async => tester.binding.setSurfaceSize(null),
        );

        await tester.pumpWidget(_buildApp(child: _buildSheet()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ajouter une plante'));
        await tester.pumpAndSettle();

        // Avant tap sur la tuile : pas encore de form sheet.
        expect(find.byType(UserPlantFormSheet), findsNothing);

        await tester.tap(find.text('Créer une plante personnalisée'));
        await tester.pumpAndSettle();

        // Après tap : le form sheet de création est affiché.
        expect(find.byType(UserPlantFormSheet), findsOneWidget);
        expect(find.text('Créer une plante'), findsOneWidget);
      },
    );

    testWidgets(
      'la tuile reste visible même quand la liste catalogue est vide',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(
          () async => tester.binding.setSurfaceSize(null),
        );

        await tester.pumpWidget(_buildApp(child: _buildSheet()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ajouter une plante'));
        await tester.pumpAndSettle();

        // Liste vide → message "Aucune plante trouvée" affiché, mais
        // la tuile de création est PRÉSENTE pour débloquer l'utilisateur.
        expect(
          find.text('Créer une plante personnalisée'),
          findsOneWidget,
        );
      },
    );
  });
}

