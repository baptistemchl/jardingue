/// Represents the user's premium entitlement.
class PremiumState {
  final bool isPremium;
  final DateTime? purchaseDate;
  final String? productId;

  const PremiumState({
    this.isPremium = false,
    this.purchaseDate,
    this.productId,
  });

  const PremiumState.free()
      : isPremium = false,
        purchaseDate = null,
        productId = null;

  PremiumState copyWith({
    bool? isPremium,
    DateTime? purchaseDate,
    String? productId,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      productId: productId ?? this.productId,
    );
  }
}
