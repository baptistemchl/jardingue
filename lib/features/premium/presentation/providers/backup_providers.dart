import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/garden_event_providers.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../../../core/providers/orchard_providers.dart';
import '../../../../core/services/crash_reporting/crash_reporting_service.dart';
import '../../domain/models/backup_metadata.dart';
import 'premium_providers.dart';

/// Fetches cloud backup metadata for the current user.
final cloudMetadataProvider =
    FutureProvider<BackupMetadata?>((ref) async {
  final user = ref.watch(firebaseUserProvider);
  if (user == null) return null;
  final repo = ref.watch(backupRepositoryProvider);
  return repo.fetchMetadata(user.uid);
});

/// Backup/restore operations notifier.
final backupNotifierProvider =
    NotifierProvider<BackupNotifier, BackupState>(BackupNotifier.new);

class BackupNotifier extends Notifier<BackupState> {
  DateTime? _lastManualBackup;

  /// Cooldown de 15 minutes entre deux backups manuels.
  static const _cooldown = Duration(minutes: 15);

  @override
  BackupState build() => const BackupState.idle();

  /// Temps restant avant de pouvoir relancer un backup manuel.
  Duration? get cooldownRemaining {
    if (_lastManualBackup == null) return null;
    final elapsed = DateTime.now().difference(_lastManualBackup!);
    if (elapsed >= _cooldown) return null;
    return _cooldown - elapsed;
  }

  Future<void> backup() async {
    if (_lastManualBackup != null &&
        DateTime.now().difference(_lastManualBackup!) < _cooldown) {
      final remaining = cooldownRemaining!;
      state = BackupState.error(
        'Veuillez patienter ${remaining.inMinutes + 1} min '
        'avant de relancer une sauvegarde.',
      );
      return;
    }

    state = const BackupState.inProgress(
      BackupOperation.backup,
    );
    try {
      final user = ref.read(firebaseUserProvider);
      if (user == null) {
        state = const BackupState.error(
          'Connexion impossible.',
        );
        return;
      }

      final repo = ref.read(backupRepositoryProvider);
      final data = await repo.exportLocalData();
      await repo.uploadBackup(user.uid, data);

      _lastManualBackup = DateTime.now();
      ref.invalidate(cloudMetadataProvider);
      state = const BackupState.success(
        BackupOperation.backup,
      );
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'BackupNotifier.backup',
      );
      state = BackupState.error(
        'Erreur de sauvegarde : $e',
      );
    }
  }

  Future<void> restore() async {
    state = const BackupState.inProgress(
      BackupOperation.restore,
    );
    try {
      final user = ref.read(firebaseUserProvider);
      if (user == null) {
        state = const BackupState.error(
          'Connexion impossible.',
        );
        return;
      }

      final repo = ref.read(backupRepositoryProvider);
      final data = await repo.downloadBackup(user.uid);

      if (data == null) {
        state = const BackupState.error(
          'Aucune sauvegarde trouvée.',
        );
        return;
      }

      await repo.importToLocal(data);

      // Invalider tous les providers qui lisent la DB
      // pour que l'UI se mette à jour après la restauration
      ref.invalidate(gardensListProvider);
      ref.invalidate(wateringRemindersProvider);
      ref.invalidate(allUserEventsProvider);
      ref.invalidate(trackedPlantsProvider);
      ref.invalidate(userFruitTreesProvider);
      ref.invalidate(cloudMetadataProvider);

      state = const BackupState.success(
        BackupOperation.restore,
      );
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'BackupNotifier.restore',
      );
      state = BackupState.error(
        'Erreur de restauration : $e',
      );
    }
  }

  void reset() => state = const BackupState.idle();
}

// ── State ──

enum BackupOperation { backup, restore }

sealed class BackupState {
  const BackupState();

  const factory BackupState.idle() = BackupIdle;
  const factory BackupState.inProgress(
    BackupOperation op,
  ) = BackupInProgress;
  const factory BackupState.success(
    BackupOperation op,
  ) = BackupSuccess;
  const factory BackupState.error(String message) =
      BackupError;
}

class BackupIdle extends BackupState {
  const BackupIdle();
}

class BackupInProgress extends BackupState {
  final BackupOperation operation;
  const BackupInProgress(this.operation);
}

class BackupSuccess extends BackupState {
  final BackupOperation operation;
  const BackupSuccess(this.operation);
}

class BackupError extends BackupState {
  final String message;
  const BackupError(this.message);
}
