import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/infrastructure/sqlite_database_connection.dart';

final databaseConnectionProvider = Provider<SqliteDatabaseConnection>((ref) {
  return SqliteDatabaseConnection();
});


final activeDatabasePathProvider = StateProvider<String?>((ref) => null);
  
final activeDatabaseConnectionProvider =
    NotifierProvider<ActiveDatabaseConnectionNotifier, Database?>(
      ActiveDatabaseConnectionNotifier.new,
    );

class ActiveDatabaseConnectionNotifier extends Notifier<Database?> {
  @override
  Database? build() {
    ref.onDispose(() {
      state?.dispose();
      ref.read(activeDatabasePathProvider.notifier).state = null;
    });
    return null;
  }

  void setActiveProjectDatabase(String path) {
    final conn = ref.read(databaseConnectionProvider);
    final db = conn.open(path);

    // Enable foreign keys
    db.execute('PRAGMA foreign_keys = ON;');

    // Update state
    state?.dispose();
    state = db;

    // ✅ store the path so WriteBackup can be called later
    ref.read(activeDatabasePathProvider.notifier).state = path;
  }
}




