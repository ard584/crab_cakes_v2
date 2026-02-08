import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/interfaces/project_database.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sql_insert_generator.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

class SqliteProjectDatabase implements ProjectDatabase {
  final String dbPath;

  SqliteProjectDatabase({required this.dbPath});

  @override
  Future<void> saveTable(TableInput table) async {
    // TODO: implement save

    // Call insert generator

    final generator = SQLInsertGenerator(table: table);

    final sql = generator.generateInsertIntoTable();
    final values = generator.generateValues();

    Database db = sqlite3.open(dbPath);

    PreparedStatement? stmt;

    try {
      // Begin transaction
      db.execute('BEGIN;');

      // Prepare & execute statement
      stmt = db.prepare(sql);
      stmt.execute(values);

      // Commit transaction
      db.execute('COMMIT;');
    } catch (e) {
      db.execute('ROLLBACK;');
      rethrow;
    } finally {
      stmt?.dispose(); // always clean up
    }
  }
}
