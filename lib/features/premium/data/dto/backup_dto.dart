import '../../domain/models/backup_data.dart';
import '../../domain/models/backup_metadata.dart';

/// Converts between domain [BackupData] and Firestore
/// JSON maps.
class BackupDto {
  const BackupDto._();

  static Map<String, dynamic> toFirestore(
    BackupData data,
  ) {
    return {
      'metadata': {
        'createdAt':
            data.metadata.createdAt.toIso8601String(),
        'gardenCount': data.metadata.gardenCount,
        'plantCount': data.metadata.plantCount,
        'eventCount': data.metadata.eventCount,
        'treeCount': data.metadata.treeCount,
      },
      'gardens': data.gardens,
      'gardenPlants': data.gardenPlants,
      'gardenEvents': data.gardenEvents,
      'userFruitTrees': data.userFruitTrees,
    };
  }

  static BackupData fromFirestore(
    Map<String, dynamic> json,
  ) {
    final meta =
        json['metadata'] as Map<String, dynamic>;
    return BackupData(
      metadata: _parseMetadata(meta),
      gardens: _parseList(json['gardens']),
      gardenPlants: _parseList(json['gardenPlants']),
      gardenEvents: _parseList(json['gardenEvents']),
      userFruitTrees:
          _parseList(json['userFruitTrees']),
    );
  }

  static BackupMetadata metadataFromFirestore(
    Map<String, dynamic> meta,
  ) =>
      _parseMetadata(meta);

  static BackupMetadata _parseMetadata(
    Map<String, dynamic> meta,
  ) {
    return BackupMetadata(
      createdAt: DateTime.parse(
        meta['createdAt'] as String,
      ),
      gardenCount: meta['gardenCount'] as int? ?? 0,
      plantCount: meta['plantCount'] as int? ?? 0,
      eventCount: meta['eventCount'] as int? ?? 0,
      treeCount: meta['treeCount'] as int? ?? 0,
    );
  }

  static List<Map<String, dynamic>> _parseList(
    dynamic raw,
  ) {
    if (raw is! List) return [];
    return raw
        .cast<Map<String, dynamic>>()
        .toList();
  }
}
