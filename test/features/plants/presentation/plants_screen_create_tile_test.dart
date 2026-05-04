import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/plants/presentation/screens/plants_screen.dart';
import 'package:jardingue/features/plants/presentation/widgets/user_plant_form_sheet.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

Plant _stubPlant() {
  final now = DateTime(2026, 1, 1);
  return Plant(
    id: 1,
    commonName: 'Tomate',
    categoryCode: 'fruit_vegetable',
    isUserModified: false,
    createdAt: now,
    updatedAt: now,
  );
}

ProviderScope _buildApp({
  List<Plant>? plants,
}) {
  // Au moins une plante stub évite le chemin _EmptyState (qui a un
  // overflow vertical dans le viewport de test, indépendant du sujet
  // testé).
  final list = plants ?? [_stubPlant()];
  return ProviderScope(
    overrides: [
      // Évite l'init DB réelle.
      databaseInitProvider.overrideWith((_) async => 0),
      // Tous les providers DB pertinents stubbés à des données stables.
      filteredPlantsProvider.overrideWith((_) async => list),
      totalPlantsCountProvider.overrideWith((_) async => list.length),
      availableCategoriesProvider.overrideWith((_) async => []),
      userPlantsListProvider.overrideWith((_) async => []),
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
      home: const PlantsScreen(),
    ),
  );
}

void main() {
  group('PlantsScreen — CTA "Créer une plante"', () {
    testWidgets(
      'la tuile primaire est visible et le FAB n\'existe plus',
      (tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        // Le FAB a été supprimé : il n'y a plus de FloatingActionButton
        // sur l'écran (la nav bar custom couvrait l'ancien FAB).
        expect(find.byType(FloatingActionButton), findsNothing);

        // La tuile « Créer une plante personnalisée » est visible.
        expect(
          find.text('Créer une plante personnalisée'),
          findsOneWidget,
        );
        expect(find.text('Pas dans la liste ? Ajoute-la'), findsOneWidget);
      },
    );

    testWidgets(
      'tap sur la tuile ouvre le UserPlantFormSheet',
      (tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        // Avant tap : pas de sheet ouvert.
        expect(find.byType(UserPlantFormSheet), findsNothing);

        await tester.tap(find.text('Créer une plante personnalisée'));
        await tester.pumpAndSettle();

        // Le sheet de création est ouvert.
        expect(find.byType(UserPlantFormSheet), findsOneWidget);
        // Mode création : titre "Créer une plante".
        expect(find.text('Créer une plante'), findsOneWidget);
      },
    );
  });
}
