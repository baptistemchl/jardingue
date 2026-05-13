import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';
import 'package:jardingue/core/providers/orchard_providers.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/orchard/domain/models/planting_type.dart';
import 'package:jardingue/features/orchard/presentation/widgets/fruit_tree_detail_sheet.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

class _RecordingNotifier extends UserFruitTreesNotifier {
  final List<Map<String, dynamic>> addCalls = [];

  @override
  AsyncValue<List<UserFruitTreeWithDetails>> build() => const AsyncData([]);

  @override
  Future<int> addTree({
    required int fruitTreeId,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    PlantingType? plantingType,
  }) async {
    addCalls.add({
      'fruitTreeId': fruitTreeId,
      'nickname': nickname,
      'variety': variety,
      'plantingDate': plantingDate,
      'location': location,
      'notes': notes,
      'plantingType': plantingType,
    });
    return 1;
  }
}

FruitTree _abricotierTree() {
  final now = DateTime(2026, 1, 1);
  return FruitTree(
    id: 12,
    commonName: 'Abricotier',
    emoji: '🟠',
    category: 'arbre_fruitier',
    droughtTolerance: true,
    selfFertile: true,
    containerSuitable: true,
    popularVarieties: '["Bergeron","Rouge du Roussillon"]',
    heightAdultM: 5.0,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildApp(Widget child, _RecordingNotifier notifier) {
  return ProviderScope(
    overrides: [
      databaseInitProvider.overrideWith((_) async => 0),
      userFruitTreesNotifierProvider.overrideWith(() => notifier),
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
    'submit avec variété libre + type=pot => addTree appelé avec ces valeurs',
    (tester) async {
      final notifier = _RecordingNotifier();
      await tester.pumpWidget(
        _buildApp(FruitTreeDetailSheet(tree: _abricotierTree()), notifier),
      );

      // Ouvrir le formulaire
      await tester.tap(find.text('Ajouter à mon verger'));
      await tester.pumpAndSettle();

      // Sélection du type "En pot"
      await tester.tap(find.text('En pot'));
      await tester.pumpAndSettle();

      // Saisie d'une variété libre (non listée)
      final varietyField = find.byType(TextField).first;
      await tester.enterText(varietyField, 'MaVariété');
      await tester.pumpAndSettle();

      // Confirmer
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(notifier.addCalls, hasLength(1));
      final call = notifier.addCalls.first;
      expect(call['fruitTreeId'], 12);
      expect(call['variety'], 'MaVariété');
      expect(call['plantingType'], PlantingType.pot);
    },
  );

  testWidgets(
    'submit sans toucher au type => plantingType = ground (défaut)',
    (tester) async {
      final notifier = _RecordingNotifier();
      await tester.pumpWidget(
        _buildApp(FruitTreeDetailSheet(tree: _abricotierTree()), notifier),
      );

      await tester.tap(find.text('Ajouter à mon verger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(notifier.addCalls.first['plantingType'], PlantingType.ground);
      expect(notifier.addCalls.first['variety'], isNull);
    },
  );
}
