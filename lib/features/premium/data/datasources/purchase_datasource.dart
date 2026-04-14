import 'dart:async';
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
  Future<ProductDetails?> queryProduct(
    String productId,
  ) async {
    final response = await _iap.queryProductDetails(
      {productId},
    );
    if (response.productDetails.isEmpty) return null;
    return response.productDetails.first;
  }

  /// Launch the native purchase flow.
  Future<PurchaseDetails> buy(
    ProductDetails product,
  ) async {
    if (!await _iap.isAvailable()) {
      throw PurchaseException(
        'Le service d\'achat n\'est pas disponible. '
        'Vérifiez que le Play Store est à jour.',
      );
    }

    final param = PurchaseParam(productDetails: product);
    final completer = Completer<PurchaseDetails>();
    _purchaseCompleter[product.id] = completer;

    final started = await _iap.buyNonConsumable(
      purchaseParam: param,
    );

    if (!started) {
      _purchaseCompleter.remove(product.id);
      throw PurchaseException('Achat non démarré.');
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
