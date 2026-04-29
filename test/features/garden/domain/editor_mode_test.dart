import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/garden/domain/editor_mode.dart';

void main() {
  group('EditorMode', () {
    test('locked: cannot drag, cannot resize, isUnlocked false', () {
      const m = EditorMode.locked;
      expect(m.canDrag, isFalse);
      expect(m.canResize, isFalse);
      expect(m.isUnlocked, isFalse);
    });

    test('move: can drag, cannot resize, isUnlocked true', () {
      const m = EditorMode.move;
      expect(m.canDrag, isTrue);
      expect(m.canResize, isFalse);
      expect(m.isUnlocked, isTrue);
    });

    test('resize: cannot drag, can resize, isUnlocked true', () {
      const m = EditorMode.resize;
      expect(m.canDrag, isFalse);
      expect(m.canResize, isTrue);
      expect(m.isUnlocked, isTrue);
    });

    test('drag and resize are mutually exclusive across all modes', () {
      for (final m in EditorMode.values) {
        expect(
          m.canDrag && m.canResize,
          isFalse,
          reason: 'Mode $m should not allow both drag and resize',
        );
      }
    });
  });
}
