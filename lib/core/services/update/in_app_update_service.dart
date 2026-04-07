import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

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
    } catch (e) {
      debugPrint('In-app update check failed: $e');
    }
  }
}
