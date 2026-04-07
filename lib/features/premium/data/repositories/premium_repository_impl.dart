import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/premium_state.dart';
import '../../domain/repositories/premium_repository.dart';
import '../datasources/purchase_datasource.dart';

const _kIsPremium = 'premium_is_premium';
const _kPurchaseDate = 'premium_purchase_date';
const _kProductId = 'premium_product_id';

class PremiumRepositoryImpl implements PremiumRepository {
  final PurchaseDatasource _purchase;

  PremiumRepositoryImpl({required PurchaseDatasource purchase})
      : _purchase = purchase;

  @override
  Future<PremiumState> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(_kIsPremium) ?? false;
    if (!isPremium) return const PremiumState.free();

    final dateMs = prefs.getInt(_kPurchaseDate);
    final productId = prefs.getString(_kProductId);
    return PremiumState(
      isPremium: true,
      purchaseDate: dateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(dateMs)
          : null,
      productId: productId,
    );
  }

  @override
  Future<void> saveState(PremiumState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPremium, state.isPremium);
    if (state.purchaseDate != null) {
      await prefs.setInt(
        _kPurchaseDate,
        state.purchaseDate!.millisecondsSinceEpoch,
      );
    }
    if (state.productId != null) {
      await prefs.setString(
        _kProductId,
        state.productId!,
      );
    }
  }

  @override
  Future<void> purchase(String productId) async {
    final product = await _purchase.queryProduct(
      productId,
    );
    if (product == null) {
      throw PurchaseException(
        'Produit introuvable sur le store.',
      );
    }
    await _purchase.buy(product);
  }

  @override
  Future<PremiumState> restorePurchases() async {
    await _purchase.restorePurchases();
    // Le résultat arrive via le stream — on attend
    // un court délai pour laisser le store répondre.
    await Future.delayed(
      const Duration(seconds: 3),
    );
    return loadState();
  }
}
