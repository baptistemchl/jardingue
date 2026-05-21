import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/database/app_database.dart';

final allJournalEntriesProvider =
    StreamProvider<List<JournalEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllJournalEntries();
});
