import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import '../crash_reporting/crash_reporting_service.dart';

/// Service de vérification et déclenchement des mises à jour via le Play Store.
class InAppUpdateService {
  /// Vérifie si une mise à jour est disponible et la propose à l'utilisateur.
  ///
  /// - Mise à jour **immédiate** si la priorité est haute (≥ 4) ou si
  ///   la mise à jour est en attente depuis trop longtemps (≥ 5 jours).
  /// - Mise à jour **flexible** (bandeau non-bloquant) sinon.
  static Future<void> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      final isUrgent = (info.updatePriority) >= 4 ||
          (info.clientVersionStalenessDays ?? 0) >= 5;

      if (isUrgent && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        // Installe la mise à jour téléchargée quand l'utilisateur quitte l'écran
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e, st) {
      // Toute PlatformException provient de Play Services et n'est pas
      // actionnable côté app : binding échoué, API indispo, device state,
      // pas de Play Store, sideload, etc. On se contente de logger.
      // Seules les erreurs Dart inattendues (cast, null, etc.) sont
      // remontées car elles révéleraient un vrai bug.
      if (e is PlatformException) {
        CrashReportingService.log(
          'Update skipped (${e.code}): ${e.message}',
        );
      } else {
        CrashReportingService.recordError(e, st,
          reason: 'InAppUpdateService.checkForUpdate',
        );
      }
    }
  }
}
