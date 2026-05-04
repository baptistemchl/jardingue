import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';
import 'package:jardingue/core/providers/orchard_providers.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/orchard/presentation/screens/orchard_screen.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

/// Force `userFruitTreesNotifierProvider` à émettre l'état [value]
/// pour piloter la branche "trees vide / non vide" du build.
class _StubNotifier extends UserFruitTreesNotifier {
  _StubNotifier(this.value);
  final AsyncValue<List<UserFruitTreeWithDetails>> value;

  @override
  AsyncValue<List<UserFruitTreeWithDetails>> build() => value;
}

UserFruitTreeWithDetails _fakeTree() {
  final now = DateTime(2026, 1, 1);
  return UserFruitTreeWithDetails(
    userTree: UserFruitTree(
      id: 1,
      fruitTreeId: 100,
      healthStatus: 'good',
      createdAt: now,
      updatedAt: now,
    ),
    fruitTree: FruitTree(
      id: 100,
      commonName: 'Pommier',
      emoji: '🍎',
      category: 'pepins',
      droughtTolerance: false,
      selfFertile: false,
      containerSuitable: false,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Widget _buildApp({
  required AsyncValue<List<UserFruitTreeWithDetails>> trees,
}) {
  return ProviderScope(
    overrides: [
      // Pas besoin d'init DB pour ces tests : on stubbe le notifier
      // qui pilote l'écran.
      databaseInitProvider.overrideWith((_) async => 0),
      userFruitTreesNotifierProvider.overrideWith(
        () => _StubNotifier(trees),
      ),
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
      home: const OrchardScreen(),
    ),
  );
}

void main() {
  group('OrchardScreen FAB visibility', () {
    testWidgets(
      'empty trees → FAB hidden, empty state CTA visible',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(trees: const AsyncData([])),
        );
        await tester.pumpAndSettle();

        // Pas de FAB : l'empty state propose déjà un CTA central.
        expect(find.byType(FloatingActionButton), findsNothing);
        // Le bouton de l'empty state ("Ajouter un arbre") est rendu
        // via ElevatedButton.icon — on vérifie sa présence indirecte.
        expect(find.byType(ElevatedButton), findsOneWidget);
      },
    );

    testWidgets(
      'with trees → FAB visible, empty state hidden',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(trees: AsyncData([_fakeTree()])),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        // L'empty state n'est plus rendu, donc l'ElevatedButton du CTA
        // central ne l'est pas non plus.
        expect(find.byType(ElevatedButton), findsNothing);
      },
    );

    testWidgets(
      'loading state → FAB hidden (pas d\'arbres connus)',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(trees: const AsyncLoading()),
        );
        // Pas de pumpAndSettle : on est en loading.
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );
  });
}
