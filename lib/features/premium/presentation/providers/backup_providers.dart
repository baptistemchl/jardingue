import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    StateNotifierProvider<BackupNotifier, BackupState>(
  (ref) => BackupNotifier(ref),
);

class BackupNotifier extends StateNotifier<BackupState> {
  final Ref _ref;

  BackupNotifier(this._ref)
      : super(const BackupState.idle());

  Future<void> backup() async {
    state = const BackupState.inProgress(
      BackupOperation.backup,
    );
    try {
      final user = _ref.read(firebaseUserProvider);
      if (user == null) {
        state = const BackupState.error(
          'Connexion impossible.',
        );
        return;
      }

      final repo = _ref.read(backupRepositoryProvider);
      final data = await repo.exportLocalData();
      await repo.uploadBackup(user.uid, data);

      _ref.invalidate(cloudMetadataProvider);
      state = const BackupState.success(
        BackupOperation.backup,
      );
    } catch (e) {
      debugPrint('Backup error: $e');
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
      final user = _ref.read(firebaseUserProvider);
      if (user == null) {
        state = const BackupState.error(
          'Connexion impossible.',
        );
        return;
      }

      final repo = _ref.read(backupRepositoryProvider);
      final data = await repo.downloadBackup(user.uid);

      if (data == null) {
        state = const BackupState.error(
          'Aucune sauvegarde trouvée.',
        );
        return;
      }

      await repo.importToLocal(data);
      state = const BackupState.success(
        BackupOperation.restore,
      );
    } catch (e) {
      debugPrint('Restore error: $e');
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
