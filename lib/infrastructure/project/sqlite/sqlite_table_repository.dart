import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/domain/models/db_row.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sql_insert_generator.dart';

class SqliteActiveProjectRepository implements ActiveProjectRepository {
  final Database db;

  SqliteActiveProjectRepository({required this.db});

  @override
  void insertRow({required String tableName, required Map<String, dynamic> values}) {
    // Call insert generator

    final generator = SQLInsertGenerator();

    final sql = generator.generateInsertStatement(tableName: tableName, values: values);
    final insertValues = generator.generateValues(values);

    if (sql == null) {
      return;
    }

    PreparedStatement? stmt;

    try {
      // Begin transaction
      db.execute('BEGIN;');

      // Prepare & execute statement
      stmt = db.prepare(sql);
      stmt.execute(insertValues);

      // Commit transaction
      db.execute('COMMIT;');
    } catch (e) {
      db.execute('ROLLBACK;');
      rethrow;
    } finally {
      stmt?.dispose(); // always clean up
    }
  }

  @override
  DbTable getTableSchema(String tableName) {
    // Get the schema so we can determine column info
    final schema = db.select("PRAGMA table_info($tableName);");

    // Convert columns to list of DbColumns
    final columns = schema.map((row) {
      return DbColumn(
        name: row['name'],
        type: row['type'],
        nullable: row['notnull'] == 0,
        primaryKey: row['pk'] == 1,
      );
    }).toList();

    // Create the dbTable, leave dbRows empty
    return DbTable(name: tableName, columns: columns);
  }

  @override
  List<DbRow> getAllRows(String tableName) {

    final result = db.select("SELECT * FROM $tableName");

    final rows = result.map((row) {
      return DbRow(values: row);
    }).toList();

    return rows;
  }

  @override
  List<DbRow> getRows(String tableName, int limit, int offset) {

    final result = db.select("SELECT * FROM $tableName LIMIT ? OFFSET ?", [limit, offset]);

    final rows = result.map((row) {
      return DbRow(values: row);
    }).toList();

    return rows;
  }
}
