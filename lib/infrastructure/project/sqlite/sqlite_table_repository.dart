import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/interfaces/table_repository.dart';
import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/presentation/view_models/db_table_view_model.dart';

class SqliteTableRepository implements TableRepository {
  final Database db;

  SqliteTableRepository({required this.db});

  @override
  Future<DbTable> getTableSchema(String tableName) async {
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
  Future<List<DbRow>> getAllRows(String tableName) async {

    final result = db.select("SELECT * FROM $tableName");

    final rows = result.rows.map((row) {
      return DbRow(values: row);
    }).toList();

    return rows;
  }

  @override
  Future<List<DbRow>> getRows(String tableName, int limit, int offset) async {

    final result = db.select("SELECT * FROM $tableName LIMIT ? OFFSET ?", [limit, offset]);

    final rows = result.rows.map((row) {
      return DbRow(values: row);
    }).toList();

    return rows;
  }
}
