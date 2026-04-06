import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/garden/domain/action_history.dart';
import 'package:jardingue/core/providers/garden_providers.dart';

/// Mock d'une action pour les tests.
class FakeAction extends GardenAction {
  int executeCount = 0;
  int undoCount = 0;

  @override
  Future<void> execute(GardenNotifier notifier) async {
    executeCount++;
  }

  @override
  Future<void> undo(GardenNotifier notifier) async {
    undoCount++;
  }

  @override
  String get description => 'FakeAction';
}

void main() {
  group('ActionHistory', () {
    late ActionHistory history;

    setUp(() => history = ActionHistory());
    tearDown(() => history.dispose());

    test('starts empty', () {
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.undoCount, 0);
      expect(history.redoCount, 0);
    });

    test('addAction enables undo', () {
      history.addAction(FakeAction());
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
      expect(history.undoCount, 1);
    });

    test('popUndo moves action to redo stack', () {
      final action = FakeAction();
      history.addAction(action);

      final popped = history.popUndo();
      expect(popped, action);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);
      expect(history.redoCount, 1);
    });

    test('popRedo moves action back to undo stack', () {
      final action = FakeAction();
      history.addAction(action);
      history.popUndo();

      final popped = history.popRedo();
      expect(popped, action);
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
    });

    test('popUndo returns null when empty', () {
      expect(history.popUndo(), isNull);
    });

    test('popRedo returns null when empty', () {
      expect(history.popRedo(), isNull);
    });

    test('addAction clears redo stack', () {
      history.addAction(FakeAction());
      history.popUndo();
      expect(history.canRedo, isTrue);

      history.addAction(FakeAction());
      expect(history.canRedo, isFalse);
    });

    test('respects maxHistory limit', () {
      for (int i = 0; i < 60; i++) {
        history.addAction(FakeAction());
      }
      expect(
        history.undoCount,
        ActionHistory.maxHistory,
      );
    });

    test('clear empties both stacks', () {
      history.addAction(FakeAction());
      history.addAction(FakeAction());
      history.popUndo();

      history.clear();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('notifies listeners on changes', () {
      int notifyCount = 0;
      history.addListener(() => notifyCount++);

      history.addAction(FakeAction());
      expect(notifyCount, 1);

      history.popUndo();
      expect(notifyCount, 2);

      history.popRedo();
      expect(notifyCount, 3);

      history.clear();
      expect(notifyCount, 4);
    });
  });
}
