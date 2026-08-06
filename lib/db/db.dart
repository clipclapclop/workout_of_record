import 'app_database.dart';

AppDatabase _db = AppDatabase();

/// The active application database.
///
/// Restore is the only operation that replaces this instance. Keeping access
/// behind a getter lets a failed restore reopen the original database instead
/// of leaving the running app attached to a closed connection.
AppDatabase get db => _db;

Future<void> checkpointAndCloseDatabaseForRestore() async {
  await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
  await _db.close();
}

Future<void> reopenDatabaseAfterFailedRestore() async {
  final reopened = AppDatabase();
  try {
    // Force the lazy connection open here so a recovery failure is reported by
    // the restore operation rather than by an unrelated screen later.
    await reopened.customSelect('SELECT 1').get();
    _db = reopened;
  } catch (_) {
    try {
      await reopened.close();
    } catch (_) {
      // Preserve the open failure; cleanup is best effort on this error path.
    }
    // Do not leave callers holding the connection closed for restore. A fresh
    // lazy connection lets a later operation retry after a transient open
    // failure, while this restore still reports recovery as incomplete.
    _db = AppDatabase();
    rethrow;
  }
}
