import '../models/premium_state.dart';

/// Contract for premium entitlement management.
abstract class PremiumRepository {
  /// Current cached premium state.
  Future<PremiumState> loadState();

  /// Persist premium state locally.
  Future<void> saveState(PremiumState state);

  /// Initiate the purchase flow for [productId].
  Future<void> purchase(String productId);

  /// Restore previous purchases from the store.
  Future<PremiumState> restorePurchases();
}
