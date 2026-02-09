import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/interfaces/table_repository.dart';
import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sql_insert_generator.dart';
import 'package:ui_prototype/presentation/view_models/db_table_view_model.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

class SqliteTableRepository implements TableRepository {
  final Database db;

  SqliteTableRepository({required this.db});

  @override
  void saveTable(TableInput table) {
    // Call insert generator

    final generator = SQLInsertGenerator(table: table);

    final sql = generator.generateInsertIntoTable();
    final values = generator.generateValues();

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

  @override
  DbTable getTableSchema(String tableName) {
    // Get the schema so we can determine column info
    final schema = db.select("PRAGMA table_info $tableName;");

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

    final rows = result.rows.map((row) {
      return DbRow(values: row);
    }).toList();

    return rows;
  }

  @override
  List<DbRow> getRows(String tableName, int limit, int offset) {

    final result = db.select("SELECT * FROM $tableName LIMIT ? OFFSET ?", [limit, offset]);

    final rows = result.rows.map((row) {
      return DbRow(values: row);
    }).toList();

    return rows;
  }
}
