import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/services/crash_reporting/crash_reporting_service.dart';
import '../../data/datasources/firestore_backup_datasource.dart';
import '../../data/datasources/purchase_datasource.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../../data/repositories/premium_repository_impl.dart';
import '../../domain/models/premium_state.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/repositories/premium_repository.dart';
import '../../../../core/providers/database_providers.dart';

// ── Datasources ──

final purchaseDatasourceProvider =
    Provider<PurchaseDatasource>((ref) {
  final ds = PurchaseDatasource();
  ref.onDispose(ds.dispose);
  return ds;
});

final firestoreDatasourceProvider =
    Provider<FirestoreBackupDatasource>(
  (ref) => FirestoreBackupDatasource(),
);

// ── Repositories ──

final premiumRepositoryProvider =
    Provider<PremiumRepository>((ref) {
  return PremiumRepositoryImpl(
    purchase: ref.watch(purchaseDatasourceProvider),
  );
});

final backupRepositoryProvider =
    Provider<BackupRepository>((ref) {
  return BackupRepositoryImpl(
    db: ref.watch(databaseProvider),
    firestore: ref.watch(firestoreDatasourceProvider),
  );
});

// ── Firebase Auth via Google Sign-In ──

final firebaseUserProvider =
    StateNotifierProvider<FirebaseUserNotifier, User?>(
  (ref) => FirebaseUserNotifier(),
);

class FirebaseUserNotifier extends StateNotifier<User?> {
  FirebaseUserNotifier()
      : super(FirebaseAuth.instance.currentUser);

  /// Lance Google Sign-In et authentifie sur Firebase.
  Future<User?> signIn() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // annulé

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance
          .signInWithCredential(credential);
      state = userCred.user;
      if (userCred.user != null) {
        CrashReportingService.setUser(userCred.user!.uid);
        CrashReportingService.log('Utilisateur connecté');
      }
      return userCred.user;
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'FirebaseUserNotifier.signIn',
      );
      rethrow;
    }
  }

  /// Déconnexion.
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      state = null;
      CrashReportingService.clearUser();
      CrashReportingService.log('Utilisateur déconnecté');
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'FirebaseUserNotifier.signOut',
      );
      rethrow;
    }
  }
}

// ── Product price ──

final premiumProductProvider =
    FutureProvider<ProductDetails?>((ref) {
  final ds = ref.watch(purchaseDatasourceProvider);
  return ds.queryProduct(kPremiumProductId);
});

// ── Premium State ──

final premiumNotifierProvider = StateNotifierProvider<
    PremiumNotifier, PremiumState>(
  (ref) => PremiumNotifier(ref),
);

class PremiumNotifier
    extends StateNotifier<PremiumState> {
  final Ref _ref;

  PremiumNotifier(this._ref)
      : super(const PremiumState.free()) {
    _init();
  }

  PremiumRepository get _repo =>
      _ref.read(premiumRepositoryProvider);

  Future<void> _init() async {
    try {
      state = await _repo.loadState();
      _ref.read(purchaseDatasourceProvider).listen(
            _onPurchaseUpdate,
          );
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'PremiumNotifier._init',
      );
    }
  }

  void _onPurchaseUpdate(PurchaseDetails detail) {
    if (detail.productID == kPremiumProductId) {
      _grantPremium(detail.productID);
    }
  }

  Future<void> _grantPremium(String productId) async {
    state = PremiumState(
      isPremium: true,
      purchaseDate: DateTime.now(),
      productId: productId,
    );
    await _repo.saveState(state);
  }

  /// Lance le flow complet : Google Sign-In puis achat.
  Future<void> purchaseWithSignIn() async {
    try {
      // 1. S'assurer que l'utilisateur est connecté
      final userNotifier = _ref.read(
        firebaseUserProvider.notifier,
      );
      var user = _ref.read(firebaseUserProvider);
      if (user == null) {
        user = await userNotifier.signIn();
        if (user == null) return; // annulé
      }

      CrashReportingService.log('Début achat premium');
      // 2. Lancer l'achat
      await _repo.purchase(kPremiumProductId);
      CrashReportingService.log('Achat premium réussi');
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'PremiumNotifier.purchaseWithSignIn',
      );
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    try {
      CrashReportingService.log('Restauration achats en cours');
      final restored = await _repo.restorePurchases();
      if (restored.isPremium) {
        state = restored;
        CrashReportingService.log('Achats restaurés: premium');
      }
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'PremiumNotifier.restorePurchases',
      );
      rethrow;
    }
  }
}
