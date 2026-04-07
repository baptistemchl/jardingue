/// Metadata about a cloud backup.
class BackupMetadata {
  final DateTime createdAt;
  final int gardenCount;
  final int plantCount;
  final int eventCount;
  final int treeCount;

  const BackupMetadata({
    required this.createdAt,
    required this.gardenCount,
    required this.plantCount,
    required this.eventCount,
    required this.treeCount,
  });

  int get totalItems =>
      gardenCount + plantCount + eventCount + treeCount;
}
