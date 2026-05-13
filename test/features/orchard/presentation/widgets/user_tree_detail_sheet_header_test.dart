import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';
import 'package:jardingue/core/providers/orchard_providers.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/orchard/domain/models/planting_type.dart';
import 'package:jardingue/features/orchard/presentation/widgets/user_tree_detail_sheet.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

class _RecordingNotifier extends UserFruitTreesNotifier {
  final List<Map<String, dynamic>> updateCalls = [];

  @override
  AsyncValue<List<UserFruitTreeWithDetails>> build() => const AsyncData([]);

  @override
  Future<void> updateTree({
    required int id,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    String? healthStatus,
    DateTime? lastPruningDate,
    DateTime? lastHarvestDate,
    double? lastYieldKg,
    PlantingType? plantingType,
  }) async {
    updateCalls.add({
      'id': id,
      'variety': variety,
      'plantingType': plantingType,
    });
  }
}

UserFruitTreeWithDetails _fakeTree({
  String? variety,
  String? plantingType,
}) {
  final now = DateTime(2026, 1, 1);
  return UserFruitTreeWithDetails(
    userTree: UserFruitTree(
      id: 42,
      fruitTreeId: 12,
      variety: variety,
      plantingType: plantingType,
      healthStatus: 'good',
      createdAt: now,
      updatedAt: now,
    ),
    fruitTree: FruitTree(
      id: 12,
      commonName: 'Abricotier',
      emoji: '🟠',
      category: 'arbre_fruitier',
      droughtTolerance: true,
      selfFertile: true,
      containerSuitable: true,
      popularVarieties: '["Bergeron"]',
      heightAdultM: 5.0,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Widget _buildApp(Widget child, _RecordingNotifier notifier) {
  return ProviderScope(
    overrides: [
      databaseInitProvider.overrideWith((_) async => 0),
      userFruitTreesNotifierProvider.overrideWith(() => notifier),
      // userFruitTreeByIdProvider is read after updateTree — we stub `null`
      // so the reload doesn't crash; the widget keeps its local state
      // and the test doesn't need the reloaded value.
      userFruitTreeByIdProvider.overrideWith((ref, id) => Future.value(null)),
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

void main() {
  testWidgets(
    'chip variete affiche la valeur stockee',
    (tester) async {
      final notifier = _RecordingNotifier();
      await tester.pumpWidget(
        _buildApp(
          UserTreeDetailSheet(tree: _fakeTree(variety: 'Bergeron')),
          notifier,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bergeron'), findsOneWidget);
    },
  );

  testWidgets(
    'chip planting type affiche "Pleine terre" par defaut si null',
    (tester) async {
      final notifier = _RecordingNotifier();
      await tester.pumpWidget(
        _buildApp(
          UserTreeDetailSheet(tree: _fakeTree()),
          notifier,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pleine terre'), findsWidgets);
    },
  );

  testWidgets(
    'chip planting type affiche la valeur stockee',
    (tester) async {
      final notifier = _RecordingNotifier();
      await tester.pumpWidget(
        _buildApp(
          UserTreeDetailSheet(tree: _fakeTree(plantingType: 'pot')),
          notifier,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('En pot'), findsOneWidget);
    },
  );
}
