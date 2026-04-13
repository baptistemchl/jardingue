import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';
import 'package:jardingue/core/providers/garden_providers.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/garden/domain/models/garden_plant_with_details.dart';
import 'package:jardingue/features/garden/presentation/widgets/editor/editor_plant_detail_sheet.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

// ── Fake data ──

final _now = DateTime(2025, 1, 1);

Plant _fakePlant() => Plant(
      id: 42,
      commonName: 'Tomate',
      categoryCode: 'fruit_vegetable',
      isUserModified: false,
      createdAt: _now,
      updatedAt: _now,
    );

GardenPlantWithDetails _fakeElement({
  int id = 1,
  int plantId = 42,
  int gardenId = 1,
  DateTime? plantedAt,
  DateTime? sowedAt,
}) {
  return GardenPlantWithDetails(
    gardenPlant: GardenPlant(
      id: id,
      gardenId: gardenId,
      plantId: plantId,
      gridX: 2,
      gridY: 3,
      widthCells: 2,
      heightCells: 2,
      plantedAt: plantedAt ?? DateTime(2025, 6, 15),
      sowedAt: sowedAt,
      createdAt: _now,
    ),
    plant: _fakePlant(),
  );
}

Garden _fakeGarden() => Garden(
      id: 1,
      name: 'Test Garden',
      widthCells: 10,
      heightCells: 10,
      cellSizeCm: 10,
      createdAt: _now,
      updatedAt: _now,
    );

Widget _buildTestApp({
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      // Stub providers that the sheet watches
      plantCompanionsProvider(42)
          .overrideWith((ref) => Future.value(<Plant>[])),
      plantAntagonistsProvider(42)
          .overrideWith((ref) => Future.value(<Plant>[])),
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
  group('EditorPlantDetailSheet - Delete flow', () {
    testWidgets('delete button is visible and triggers dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: EditorPlantDetailSheet(
          element: _fakeElement(),
          garden: _fakeGarden(),
          maxWidthM: 1.0,
          maxHeightM: 1.0,
          onUpdate: (_, __) {},
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Scroll down to find the delete button
      final scrollable = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.byType(OutlinedButton),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // AlertDialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('confirming dialog calls onDelete', (tester) async {
      bool deleteCalled = false;

      await tester.pumpWidget(_buildTestApp(
        child: EditorPlantDetailSheet(
          element: _fakeElement(),
          garden: _fakeGarden(),
          maxWidthM: 1.0,
          maxHeightM: 1.0,
          onUpdate: (_, __) {},
          onDelete: () => deleteCalled = true,
        ),
      ));
      await tester.pumpAndSettle();

      // Scroll to delete
      final scrollable = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.byType(OutlinedButton),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // Find confirm button in dialog (last TextButton)
      final dialogButtons = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last);
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    testWidgets('cancelling dialog does NOT call onDelete', (tester) async {
      bool deleteCalled = false;

      await tester.pumpWidget(_buildTestApp(
        child: EditorPlantDetailSheet(
          element: _fakeElement(),
          garden: _fakeGarden(),
          maxWidthM: 1.0,
          maxHeightM: 1.0,
          onUpdate: (_, __) {},
          onDelete: () => deleteCalled = true,
        ),
      ));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.byType(OutlinedButton),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // Tap cancel (first TextButton in dialog)
      final dialogButtons = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.first);
      await tester.pumpAndSettle();

      expect(deleteCalled, isFalse);
    });
  });

  group('EditorPlantDetailSheet - Date display', () {
    testWidgets('shows plantedAt date row', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: EditorPlantDetailSheet(
          element: _fakeElement(plantedAt: DateTime(2025, 6, 15)),
          garden: _fakeGarden(),
          maxWidthM: 1.0,
          maxHeightM: 1.0,
          onUpdate: (_, __) {},
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('15/06/2025'), findsOneWidget);
    });

    testWidgets('shows sowedAt date row when present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: EditorPlantDetailSheet(
          element: _fakeElement(
            plantedAt: DateTime(2025, 6, 15),
            sowedAt: DateTime(2025, 3, 1),
          ),
          garden: _fakeGarden(),
          maxWidthM: 1.0,
          maxHeightM: 1.0,
          onUpdate: (_, __) {},
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('15/06/2025'), findsOneWidget);
      expect(find.text('01/03/2025'), findsOneWidget);
    });

    testWidgets('tapping date row opens DatePicker', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: EditorPlantDetailSheet(
          element: _fakeElement(plantedAt: DateTime(2025, 6, 15)),
          garden: _fakeGarden(),
          maxWidthM: 1.0,
          maxHeightM: 1.0,
          onUpdate: (_, __) {},
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Tap on the date text
      await tester.tap(find.text('15/06/2025'));
      await tester.pumpAndSettle();

      // DatePicker dialog should appear
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });

  group('GardenPlantWithDetails model', () {
    test('id returns gardenPlant.id not plant.id', () {
      final element = _fakeElement(id: 99, plantId: 42);
      expect(element.id, 99);
      expect(element.gardenPlant.plantId, 42);
      expect(element.id, isNot(element.gardenPlant.plantId));
    });

    test('isZone when plantId is 0', () {
      final zone = _fakeElement(plantId: 0);
      expect(zone.isZone, isTrue);
    });

    test('isPendingPlacement when coordinates negative', () {
      final pending = GardenPlantWithDetails(
        gardenPlant: GardenPlant(
          id: 1, gardenId: 1, plantId: 1,
          gridX: -1, gridY: -1,
          widthCells: 1, heightCells: 1,
          createdAt: _now,
        ),
      );
      expect(pending.isPendingPlacement, isTrue);
    });
  });
}
