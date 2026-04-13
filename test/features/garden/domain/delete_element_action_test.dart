import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/garden/domain/action_history.dart';

void main() {
  group('DeleteElementAction', () {
    test('stores correct plantId for undo (not gardenPlant id)', () {
      const gardenPlantId = 42;
      const catalogPlantId = 7;

      final action = DeleteElementAction(
        elementId: gardenPlantId,
        gardenId: 1,
        isZone: false,
        plantId: catalogPlantId,
        zoneType: 'null',
        xMeters: 1.0,
        yMeters: 2.0,
        widthMeters: 0.5,
        heightMeters: 0.5,
      );

      // plantId should be the catalog plant id, not the gardenPlant id
      expect(action.plantId, catalogPlantId);
      expect(action.plantId, isNot(equals(gardenPlantId)));
    });

    test('description is Suppression', () {
      final action = DeleteElementAction(
        elementId: 1,
        gardenId: 1,
        isZone: false,
        plantId: 1,
        zoneType: 'null',
        xMeters: 0,
        yMeters: 0,
        widthMeters: 1,
        heightMeters: 1,
      );

      expect(action.description, 'Suppression');
    });

    test('zone action has isZone true', () {
      final action = DeleteElementAction(
        elementId: 1,
        gardenId: 1,
        isZone: true,
        plantId: null,
        zoneType: 'compost',
        xMeters: 0,
        yMeters: 0,
        widthMeters: 1,
        heightMeters: 1,
      );

      expect(action.isZone, isTrue);
    });
  });

  group('ActionHistory', () {
    late ActionHistory history;

    setUp(() => history = ActionHistory());

    test('starts empty', () {
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('addAction enables undo', () {
      final action = _FakeAction();
      history.addAction(action);
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
    });

    test('popUndo moves action to redo stack', () {
      final action = _FakeAction();
      history.addAction(action);

      final popped = history.popUndo();
      expect(popped, same(action));
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);
    });

    test('popRedo moves action back to undo stack', () {
      history.addAction(_FakeAction());
      history.popUndo();

      final popped = history.popRedo();
      expect(popped, isNotNull);
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
    });

    test('addAction clears redo stack', () {
      history.addAction(_FakeAction());
      history.popUndo();
      expect(history.canRedo, isTrue);

      history.addAction(_FakeAction());
      expect(history.canRedo, isFalse);
    });

    test('respects maxHistory limit', () {
      for (var i = 0; i < 60; i++) {
        history.addAction(_FakeAction());
      }
      expect(history.undoCount, ActionHistory.maxHistory);
    });

    test('clear empties both stacks', () {
      history.addAction(_FakeAction());
      history.addAction(_FakeAction());
      history.popUndo();
      history.clear();

      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });
  });
}

class _FakeAction extends GardenAction {
  @override
  Future<void> execute(notifier) async {}

  @override
  Future<void> undo(notifier) async {}

  @override
  String get description => 'Fake';
}
