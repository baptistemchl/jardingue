import 'dart:async';
import 'dart:isolate';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service centralisé de crash reporting via Firebase Crashlytics.
///
/// Fournit des logs structurés avec contexte précis pour chaque erreur,
/// tout en garantissant que l'utilisateur n'est jamais bloqué.
class CrashReportingService {
  CrashReportingService._();

  static bool get _isFirebaseReady {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  static FirebaseCrashlytics get _crashlytics =>
      FirebaseCrashlytics.instance;

  /// Initialise tous les handlers d'erreurs globaux.
  ///
  /// Doit être appelé dans main() après Firebase.initializeApp().
  static Future<void> initialize() async {
    // Désactiver en mode debug pour ne pas polluer la console Firebase
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Handler pour les erreurs Flutter (widgets, rendering, etc.)
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_isPdfPreviewRasterUnmountRace(details)) {
        // Race condition connue du package `printing` (raster.dart:169) :
        // widget.pages est lu apres unmount quand on quitte la preview
        // pendant la generation. Conserve en non-fatal pour garder la
        // trace sans polluer le taux de crash.
        _crashlytics.recordError(
          details.exception,
          details.stack,
          reason: 'printing: PdfPreviewRaster unmount race (known bug)',
          fatal: false,
        );
      } else {
        _crashlytics.recordFlutterFatalError(details);
      }
      // En debug, on affiche aussi dans la console
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Handler pour les erreurs asynchrones non-Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(
        error,
        stack,
        fatal: true,
        reason: 'PlatformDispatcher.onError (erreur non capturée)',
      );
      if (kDebugMode) {
        debugPrint('FATAL non-Flutter: $error\n$stack');
      }
      return true;
    };

    // Handler pour les erreurs dans les Isolates
    Isolate.current.addErrorListener(RawReceivePort((pair) {
      final List<dynamic> errorAndStack = pair as List<dynamic>;
      _crashlytics.recordError(
        errorAndStack.first,
        StackTrace.fromString(errorAndStack.last as String? ?? ''),
        fatal: true,
        reason: 'Isolate.current error',
      );
    }).sendPort);
  }

  /// Detecte la race condition de `printing` (PdfPreviewRaster) qui lit
  /// `widget.pages` apres unmount. On verifie trois conditions pour eviter
  /// de masquer d'autres bugs du meme package.
  static bool _isPdfPreviewRasterUnmountRace(
    FlutterErrorDetails details,
  ) {
    if (details.library != 'printing') return false;
    if (details.context?.toString().contains('rastering a PDF') != true) {
      return false;
    }
    final stack = details.stack?.toString() ?? '';
    return stack.contains('PdfPreviewRaster._raster') &&
        stack.contains('State.widget');
  }

  // ──────────────────────────────────────────────
  // Identification utilisateur
  // ──────────────────────────────────────────────

  /// Associe un utilisateur Firebase aux crash reports.
  static Future<void> setUser(String uid) async {
    if (!_isFirebaseReady) return;
    await _crashlytics.setUserIdentifier(uid);
  }

  /// Supprime l'identifiant utilisateur (déconnexion).
  static Future<void> clearUser() async {
    if (!_isFirebaseReady) return;
    await _crashlytics.setUserIdentifier('');
  }

  // ──────────────────────────────────────────────
  // Clés contextuelles
  // ──────────────────────────────────────────────

  /// Ajoute une clé contextuelle visible dans le dashboard Crashlytics.
  static Future<void> setKey(String key, Object value) async {
    if (!_isFirebaseReady) return;
    await _crashlytics.setCustomKey(key, value);
  }

  // ──────────────────────────────────────────────
  // Breadcrumbs (fil d'Ariane)
  // ──────────────────────────────────────────────

  /// Enregistre un breadcrumb (message de log visible dans Crashlytics).
  /// Utile pour tracer le parcours utilisateur avant un crash.
  static Future<void> log(String message) async {
    if (kDebugMode) debugPrint('[Crashlytics] $message');
    if (!_isFirebaseReady) return;
    await _crashlytics.log(message);
  }

  // ──────────────────────────────────────────────
  // Erreurs non-fatales
  // ──────────────────────────────────────────────

  /// Enregistre une erreur non-fatale avec contexte complet.
  ///
  /// [error] L'exception ou erreur.
  /// [stack] La stack trace.
  /// [reason] Description courte du contexte (ex: "WeatherService.getWeather").
  /// [extra] Données supplémentaires attachées comme custom keys.
  static Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    required String reason,
    Map<String, Object>? extra,
  }) async {
    if (kDebugMode) {
      debugPrint('[$reason] $error');
      if (stack != null) debugPrint('$stack');
    }

    if (!_isFirebaseReady) return;

    // Ajouter les custom keys temporaires pour cette erreur
    if (extra != null) {
      for (final entry in extra.entries) {
        await _crashlytics.setCustomKey(
          'err_${entry.key}',
          entry.value,
        );
      }
    }

    await _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: false,
    );
  }

  /// Enregistre une erreur fatale (sera comptée comme un crash).
  static Future<void> recordFatalError(
    dynamic error,
    StackTrace? stack, {
    required String reason,
  }) async {
    if (kDebugMode) {
      debugPrint('[FATAL][$reason] $error');
      if (stack != null) debugPrint('$stack');
    }

    if (!_isFirebaseReady) return;

    await _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: true,
    );
  }

  // ──────────────────────────────────────────────
  // Helper : wrap sécurisé avec fallback
  // ──────────────────────────────────────────────

  /// Exécute [action] en capturant toute erreur vers Crashlytics.
  /// Retourne [fallback] si une erreur survient (l'utilisateur n'est jamais bloqué).
  static Future<T> guard<T>({
    required Future<T> Function() action,
    required T fallback,
    required String reason,
  }) async {
    try {
      return await action();
    } catch (e, st) {
      await recordError(e, st, reason: reason);
      return fallback;
    }
  }

  /// Exécute [action] en capturant toute erreur vers Crashlytics.
  /// Retourne null si une erreur survient.
  static Future<T?> guardNullable<T>({
    required Future<T> Function() action,
    required String reason,
  }) async {
    try {
      return await action();
    } catch (e, st) {
      await recordError(e, st, reason: reason);
      return null;
    }
  }

  /// Comme [guard] mais synchrone.
  static T guardSync<T>({
    required T Function() action,
    required T fallback,
    required String reason,
  }) {
    try {
      return action();
    } catch (e, st) {
      recordError(e, st, reason: reason);
      return fallback;
    }
  }
}
