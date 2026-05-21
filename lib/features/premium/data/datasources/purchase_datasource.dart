import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product ID — must match Play Console / App Store Connect.
const kPremiumProductId = 'premium_cloud_backup';

/// Wraps [InAppPurchase] with a simpler API.
class PurchaseDatasource {
  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  PurchaseDatasource({InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance;

  final _purchaseCompleter =
      <String, Completer<PurchaseDetails>>{};

  /// true if the store is available.
  Future<bool> get isAvailable => _iap.isAvailable();

  /// Start listening to purchase updates.
  void listen(void Function(PurchaseDetails) onDone) {
    _sub = _iap.purchaseStream.listen((list) {
      for (final detail in list) {
        _handleUpdate(detail, onDone);
      }
    });
  }

  /// Stop listening.
  void dispose() {
    _sub?.cancel();
  }

  /// Fetch product details for [productId].
  ///
  /// Renvoie `null` après 6s si le store ne répond pas (cas typique
  /// en debug local sans Play Services), pour éviter de bloquer
  /// l'UI sur un spinner infini.
  ///
  /// Logue en debug le détail de la réponse Play Store (productDetails,
  /// notFoundIDs, error) pour diagnostiquer les cas « le prix ne
  /// s'affiche jamais » → presque toujours côté config Play Console.
  Future<ProductDetails?> queryProduct(
    String productId,
  ) async {
    try {
      final available = await _iap.isAvailable();
      if (kDebugMode) {
        debugPrint('[IAP] queryProduct($productId) — store available: $available');
      }
      if (!available) return null;
      final response = await _iap
          .queryProductDetails({productId})
          .timeout(const Duration(seconds: 6));
      if (kDebugMode) {
        debugPrint(
          '[IAP] queryProductDetails response → '
          'found: ${response.productDetails.length}, '
          'notFoundIDs: ${response.notFoundIDs}, '
          'error: ${response.error?.message ?? "none"}',
        );
        for (final pd in response.productDetails) {
          debugPrint(
            '[IAP]   • ${pd.id} = ${pd.price} (${pd.currencyCode}) — ${pd.title}',
          );
        }
      }
      if (response.productDetails.isEmpty) return null;
      return response.productDetails.first;
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('[IAP] queryProduct($productId) — TIMEOUT after 6s');
      }
      return null;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[IAP] queryProduct($productId) — ERROR: $e\n$st');
      }
      return null;
    }
  }

  /// Launch the native purchase flow.
  Future<PurchaseDetails> buy(
    ProductDetails product,
  ) async {
    if (!await _iap.isAvailable()) {
      throw PurchaseException(
        'L\'achat sera bientôt disponible.',
      );
    }

    // Re-vérifie que le produit est *réellement* vendable juste avant
    // d'appeler launchBillingFlow. Sans ce garde, si Play Store répond
    // avec un PendingIntent null (compte marchand pas encore validé,
    // produit pas encore propagé, fiscalité en cours…), la lib Google
    // crashe en NPE dans ProxyBillingActivity.onCreate et on ne peut
    // pas l'attraper depuis Dart.
    final fresh = await queryProduct(product.id);
    if (fresh == null) {
      throw PurchaseException(
        'L\'achat sera bientôt disponible.',
      );
    }

    final param = PurchaseParam(productDetails: fresh);
    final completer = Completer<PurchaseDetails>();
    _purchaseCompleter[fresh.id] = completer;

    final started = await _iap.buyNonConsumable(
      purchaseParam: param,
    );

    if (!started) {
      _purchaseCompleter.remove(fresh.id);
      throw PurchaseException(
        'L\'achat sera bientôt disponible.',
      );
    }
    return completer.future;
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _handleUpdate(
    PurchaseDetails detail,
    void Function(PurchaseDetails) onDone,
  ) {
    if (detail.pendingCompletePurchase) {
      _iap.completePurchase(detail);
    }
    final completer = _purchaseCompleter.remove(
      detail.productID,
    );
    if (detail.status == PurchaseStatus.purchased ||
        detail.status == PurchaseStatus.restored) {
      completer?.complete(detail);
      onDone(detail);
    } else if (detail.status == PurchaseStatus.error) {
      completer?.completeError(
        PurchaseException(
          detail.error?.message ?? 'Erreur inconnue',
        ),
      );
    } else if (detail.status == PurchaseStatus.canceled) {
      completer?.completeError(
        PurchaseException('Achat annulé.'),
      );
    }
  }
}

class PurchaseException implements Exception {
  final String message;
  const PurchaseException(this.message);

  @override
  String toString() => message;
}
