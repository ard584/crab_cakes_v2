import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/infrastructure/sqlite_database_connection.dart';

final databaseConnectionProvider = Provider<SqliteDatabaseConnection>((ref) {
  return SqliteDatabaseConnection();
});

final activeDatabaseConnectionProvider =
    NotifierProvider<ActiveDatabaseConnectionNotifier, Database?>(
      ActiveDatabaseConnectionNotifier.new,
    );

class ActiveDatabaseConnectionNotifier extends Notifier<Database?> {
  @override
  Database? build() {
    ref.onDispose(() => state?.dispose());
    return null;
  }

  void setActiveProjectDatabase(String path) {
    // Get database connection, open database using its open method
    final conn = ref.read(databaseConnectionProvider);
    final db = conn.open(path);

    // Enable foreign keys
    db.execute('PRAGMA foreign_keys = ON;');

    // Update state
    state?.dispose();
    state = db;
  }
}
