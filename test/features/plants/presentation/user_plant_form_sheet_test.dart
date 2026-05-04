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

/// Fake repository qui enregistre les appels critiques pour le form
/// sheet (insert / update / delete / usage). Toutes les autres méthodes
/// renvoient des résultats neutres.
class _FakeRepo implements PlantRepository {
  UserPlantInput? lastInsertInput;
  List<int> lastInsertCompanions = [];
  List<int> lastInsertAntagonists = [];

  int? lastUpdateId;
  UserPlantInput? lastUpdateInput;

  int? lastDeleteId;

  UserPlantUsageInfo nextUsage = const UserPlantUsageInfo(
    gardenNames: [],
    eventCount: 0,
  );

  @override
  Future<int> insertUserPlant(
    UserPlantInput input, {
    List<int> companions = const [],
    List<int> antagonists = const [],
  }) async {
    lastInsertInput = input;
    lastInsertCompanions = companions;
    lastInsertAntagonists = antagonists;
    return 1000000;
  }

  @override
  Future<void> updateUserPlant(
    int id,
    UserPlantInput input, {
    List<int>? companions,
    List<int>? antagonists,
  }) async {
    lastUpdateId = id;
    lastUpdateInput = input;
  }

  @override
  Future<void> deleteUserPlant(int id) async {
    lastDeleteId = id;
  }

  @override
  Future<UserPlantUsageInfo> getUserPlantUsage(int id) async => nextUsage;

  // ── Méthodes non sollicitées par le form mais qui doivent répondre ──

  @override
  Future<List<Plant>> getCompanions(int plantId) async => [];

  @override
  Future<List<Plant>> getAntagonists(int plantId) async => [];

  @override
  Future<Plant?> getPlantById(int id) async => null;

  @override
  Future<List<Plant>> getAllPlantsSorted() async => [];

  @override
  Future<List<Plant>> getAllUserPlants() async => [];

  @override
  Future<List<Plant>> searchPlants(String query) async => [];

  @override
  Future<int> countPlants() async => 0;

  @override
  Future<int> countCatalogPlants() async => 0;

  @override
  Future<Map<String, int>> getCategoryCounts() async => {};

  @override
  Future<Map<String, int>> getCatalogCategoryCounts() async => {};

  @override
  Future<List<Plant>> getPlantsByIds(List<int> ids) async => [];

  @override
  Future<List<Plant>> getFilteredPlants({
    String? searchQuery,
    String? categoryCode,
    String? sunExposureContains,
  }) async =>
      [];
}

Plant _existingUserPlant() {
  final now = DateTime(2026, 1, 1);
  return Plant(
    id: 1000000,
    commonName: 'Pastèque',
    categoryCode: 'fruit_vegetable',
    spacingBetweenPlants: 100,
    spacingBetweenRows: 150,
    sowingCalendar:
        '{"monthly_period":{"April":"Oui","May":"Oui"}}',
    isUserModified: true,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildApp({
  required _FakeRepo repo,
  Plant? initialPlant,
}) {
  return ProviderScope(
    overrides: [
      databaseInitProvider.overrideWith((_) async => 0),
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
        body: UserPlantFormSheet(initialPlant: initialPlant),
      ),
    ),
  );
}

void main() {
  // ============================================
  // VALIDATION
  // ============================================

  group('UserPlantFormSheet — validation', () {
    testWidgets(
      'saving with empty name → error shown, repo not called',
      (tester) async {
        final repo = _FakeRepo();
        await tester.pumpWidget(_buildApp(repo: repo));
        await tester.pumpAndSettle();

        // Le bouton "Créer" est visible (mode création).
        await tester.tap(find.widgetWithText(ElevatedButton, 'Créer'));
        await tester.pumpAndSettle();

        expect(
          find.text('Le nom commun est obligatoire.'),
          findsOneWidget,
        );
        expect(repo.lastInsertInput, isNull);
      },
    );

    testWidgets(
      'saving with name but no spacing → error shown',
      (tester) async {
        final repo = _FakeRepo();
        await tester.pumpWidget(_buildApp(repo: repo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'ex: Pastèque'),
          'Pastèque',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Créer'));
        await tester.pumpAndSettle();

        // Validation espacement plants déclenchée.
        expect(
          find.textContaining(
            'espacement entre plants',
          ),
          findsOneWidget,
        );
        expect(repo.lastInsertInput, isNull);
      },
    );

    testWidgets(
      'saving without any month checked → error shown',
      (tester) async {
        final repo = _FakeRepo();
        await tester.pumpWidget(_buildApp(repo: repo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'ex: Pastèque'),
          'Pastèque',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'ex: 100'),
          '100',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'ex: 150'),
          '150',
        );
        // Pas de mois coché.
        await tester.tap(find.widgetWithText(ElevatedButton, 'Créer'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('au moins un mois'),
          findsOneWidget,
        );
        expect(repo.lastInsertInput, isNull);
      },
    );
  });

  // ============================================
  // CREATION HAPPY PATH
  // ============================================

  group('UserPlantFormSheet — création', () {
    testWidgets(
      'remplir tous les champs requis + cocher un mois → insertUserPlant',
      (tester) async {
        // Viewport agrandi pour la même raison qu'en mode édition.
        await tester.binding.setSurfaceSize(const Size(800, 2200));
        addTearDown(
          () async => tester.binding.setSurfaceSize(null),
        );
        final repo = _FakeRepo();
        await tester.pumpWidget(_buildApp(repo: repo));
        await tester.pumpAndSettle();

        // Cible chaque champ par son hint pour ne pas dépendre de
        // l'ordre des TextFields rendus (les dropdowns en interne
        // ont aussi des TextField).
        await tester.enterText(
          find.widgetWithText(TextField, 'ex: Pastèque'),
          'Pastèque',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'ex: 100'),
          '100',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'ex: 150'),
          '150',
        );

        // Coche le mois "Avr" (avril) dans la grille semis (la
        // première grille rencontrée, section Calendriers ouverte
        // par défaut).
        await tester.tap(find.text('Avr').first);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Créer'));
        await tester.pumpAndSettle();

        expect(repo.lastInsertInput, isNotNull);
        expect(repo.lastInsertInput!.commonName, 'Pastèque');
        expect(repo.lastInsertInput!.spacingBetweenPlants, 100);
        expect(repo.lastInsertInput!.spacingBetweenRows, 150);
        expect(repo.lastInsertInput!.categoryCode, 'fruit_vegetable');
        expect(
          repo.lastInsertInput!.sowingCalendarJson,
          contains('"April":"Oui"'),
        );
      },
    );
  });

  // ============================================
  // EDIT MODE — PREFILL
  // ============================================

  group('UserPlantFormSheet — édition', () {
    testWidgets(
      'mode édition pré-remplit les champs depuis initialPlant',
      (tester) async {
        // Viewport agrandi pour que la ListView render le bouton
        // "Supprimer" en bas, qui ne tient pas dans 600px de hauteur.
        await tester.binding.setSurfaceSize(const Size(800, 2200));
        addTearDown(
          () async => tester.binding.setSurfaceSize(null),
        );
        final repo = _FakeRepo();
        await tester.pumpWidget(_buildApp(
          repo: repo,
          initialPlant: _existingUserPlant(),
        ));
        await tester.pumpAndSettle();

        // Header en mode édition.
        expect(find.text('Modifier la plante'), findsOneWidget);
        // Nom pré-rempli.
        expect(
          find.widgetWithText(TextField, 'Pastèque'),
          findsOneWidget,
        );
        // Espacements pré-remplis.
        expect(
          find.widgetWithText(TextField, '100'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextField, '150'),
          findsOneWidget,
        );
        // Bouton "Enregistrer" (pas "Créer").
        expect(
          find.widgetWithText(ElevatedButton, 'Enregistrer'),
          findsOneWidget,
        );
        // Bouton "Supprimer cette plante" présent.
        expect(find.text('Supprimer cette plante'), findsOneWidget);
      },
    );

    testWidgets(
      'tap "Enregistrer" → updateUserPlant appelé avec le bon id',
      (tester) async {
        final repo = _FakeRepo();
        await tester.pumpWidget(_buildApp(
          repo: repo,
          initialPlant: _existingUserPlant(),
        ));
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Enregistrer'),
        );
        await tester.pumpAndSettle();

        expect(repo.lastUpdateId, 1000000);
        expect(repo.lastUpdateInput?.commonName, 'Pastèque');
      },
    );
  });

  // ============================================
  // DELETE FLOW
  // ============================================

  group('UserPlantFormSheet — suppression', () {
    /// Le formulaire est long ; on agrandit le viewport pour que le
    /// bouton "Supprimer cette plante" et la sticky save bar tiennent
    /// ensemble sans collision et que la dialog soit clickable.
    Future<void> resizeForDelete(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2200));
      addTearDown(
        () async => tester.binding.setSurfaceSize(null),
      );
    }
    testWidgets(
      'suppression sans usage → dialog simple sans warning',
      (tester) async {
        await resizeForDelete(tester);
        final repo = _FakeRepo();
        repo.nextUsage = const UserPlantUsageInfo(
          gardenNames: [],
          eventCount: 0,
        );
        await tester.pumpWidget(_buildApp(
          repo: repo,
          initialPlant: _existingUserPlant(),
        ));
        await tester.pumpAndSettle();

        // Scroll jusqu'au bouton supprimer puis tap.
        // Tape directement sur le TextButton "Supprimer cette
        // plante" : avec le viewport agrandi par setUp, il est
        // entièrement visible.
        final deleteBtn = find.widgetWithText(
          TextButton,
          'Supprimer cette plante',
        );
        await tester.ensureVisible(deleteBtn);
        await tester.pumpAndSettle();
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Dialog simple : pas de warning ⚠️ ni de mention de potager.
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.textContaining('figure encore dans tes plans'),
          findsNothing,
        );
        expect(
          find.textContaining('Elle sera retirée de'),
          findsNothing,
        );

        // Confirme la suppression.
        await tester.tap(
          find.widgetWithText(TextButton, 'Supprimer'),
        );
        await tester.pumpAndSettle();

        expect(repo.lastDeleteId, 1000000);
      },
    );

    testWidgets(
      'suppression avec usage → dialog enrichi avec gardens et events',
      (tester) async {
        await resizeForDelete(tester);
        final repo = _FakeRepo();
        repo.nextUsage = const UserPlantUsageInfo(
          gardenNames: ['Mon potager', 'Terrasse'],
          eventCount: 3,
        );
        await tester.pumpWidget(_buildApp(
          repo: repo,
          initialPlant: _existingUserPlant(),
        ));
        await tester.pumpAndSettle();

        // Tape directement sur le TextButton "Supprimer cette
        // plante" : avec le viewport agrandi par setUp, il est
        // entièrement visible.
        final deleteBtn = find.widgetWithText(
          TextButton,
          'Supprimer cette plante',
        );
        await tester.ensureVisible(deleteBtn);
        await tester.pumpAndSettle();
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Dialog enrichi : warning + gardens + events + irréversible.
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.textContaining('figure encore dans tes plans'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Mon potager, Terrasse'),
          findsOneWidget,
        );
        expect(
          find.textContaining('3 événement(s)'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Cette action est irréversible'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'annuler la suppression ne déclenche pas deleteUserPlant',
      (tester) async {
        await resizeForDelete(tester);
        final repo = _FakeRepo();
        await tester.pumpWidget(_buildApp(
          repo: repo,
          initialPlant: _existingUserPlant(),
        ));
        await tester.pumpAndSettle();

        // Tape directement sur le TextButton "Supprimer cette
        // plante" : avec le viewport agrandi par setUp, il est
        // entièrement visible.
        final deleteBtn = find.widgetWithText(
          TextButton,
          'Supprimer cette plante',
        );
        await tester.ensureVisible(deleteBtn);
        await tester.pumpAndSettle();
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(TextButton, 'Annuler'),
        );
        await tester.pumpAndSettle();

        expect(repo.lastDeleteId, isNull);
      },
    );
  });
}
