import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/premium/domain/models/backup_metadata.dart';
import 'package:jardingue/features/premium/domain/models/premium_state.dart';

void main() {
  group('PremiumState', () {
    test('free state is not premium', () {
      const state = PremiumState.free();
      expect(state.isPremium, isFalse);
      expect(state.purchaseDate, isNull);
      expect(state.productId, isNull);
    });

    test('copyWith updates fields correctly', () {
      const state = PremiumState.free();
      final now = DateTime.now();
      final updated = state.copyWith(
        isPremium: true,
        purchaseDate: now,
        productId: 'test_product',
      );

      expect(updated.isPremium, isTrue);
      expect(updated.purchaseDate, equals(now));
      expect(updated.productId, equals('test_product'));
    });

    test('copyWith preserves unmodified fields', () {
      final state = PremiumState(
        isPremium: true,
        purchaseDate: DateTime(2026, 1, 1),
        productId: 'abc',
      );
      final updated = state.copyWith(isPremium: false);

      expect(updated.isPremium, isFalse);
      expect(updated.productId, equals('abc'));
    });
  });

  group('BackupMetadata', () {
    test('totalItems sums all counts', () {
      final meta = BackupMetadata(
        createdAt: DateTime(2026, 1, 1),
        gardenCount: 2,
        plantCount: 10,
        eventCount: 30,
        treeCount: 5,
      );
      expect(meta.totalItems, equals(47));
    });
  });
}
