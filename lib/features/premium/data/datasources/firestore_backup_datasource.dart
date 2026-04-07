import 'package:cloud_firestore/cloud_firestore.dart';

/// Low-level Firestore operations for backup documents.
class FirestoreBackupDatasource {
  final FirebaseFirestore _firestore;

  FirestoreBackupDatasource({FirebaseFirestore? firestore})
      : _firestore =
            firestore ?? FirebaseFirestore.instance;

  DocumentReference _doc(String userId) =>
      _firestore.collection('backups').doc(userId);

  /// Write the full backup document.
  Future<void> write(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _doc(userId).set(data);
  }

  /// Read the full backup document.
  Future<Map<String, dynamic>?> read(
    String userId,
  ) async {
    final snap = await _doc(userId).get();
    return snap.data() as Map<String, dynamic>?;
  }

  /// Read only the metadata sub-map.
  Future<Map<String, dynamic>?> readMetadata(
    String userId,
  ) async {
    final data = await read(userId);
    if (data == null) return null;
    return data['metadata'] as Map<String, dynamic>?;
  }
}
