import '../models/backup_data.dart';
import '../models/backup_metadata.dart';

/// Contract for cloud backup operations.
abstract class BackupRepository {
  /// Export all local data into a [BackupData].
  Future<BackupData> exportLocalData();

  /// Upload [data] to the cloud for [userId].
  Future<void> uploadBackup(String userId, BackupData data);

  /// Download backup metadata (without full data).
  Future<BackupMetadata?> fetchMetadata(String userId);

  /// Download the full backup.
  Future<BackupData?> downloadBackup(String userId);

  /// Restore [data] into the local database.
  Future<void> importToLocal(BackupData data);
}
