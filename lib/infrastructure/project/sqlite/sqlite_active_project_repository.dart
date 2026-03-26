import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/project/interfaces/active_project/insert_generator.dart';
import 'package:ui_prototype/application/project/interfaces/active_project/update_generator.dart';
import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';
import 'package:ui_prototype/domain/models/db_row.dart';

class SqliteActiveProjectRepository
    implements ActiveProjectRepository<SqliteRowIdentifier> {
  final Database db;
  final InsertGenerator insert;
  final UpdateGenerator update;

  SqliteActiveProjectRepository({
    required this.db,
    required this.insert,
    required this.update,
  });

  @override
  void insertRow({
    required String tableName,
    required Map<String, dynamic> values,
  }) {
    // Call insert generator

    final record = insert.generate(tableName, values);
    final sql = record.sql;
    final insertValues = record.data;

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
  List<DbRow<SqliteRowIdentifier>> getAllRows(String tableName) {
    final result = db.select("SELECT rowid AS _rowid_, * FROM $tableName");

    return _convertToDbRow(result);
  }

  List<DbRow<SqliteRowIdentifier>> _convertToDbRow(ResultSet result) {
    final rows = result.map((row) {
      final identifier = SqliteRowIdentifier(
        name: "rowid",
        value: row["_rowid_"],
      );

      final Map<String, dynamic> filteredRow = Map.from(row);
      filteredRow.remove('_rowid_');

      return DbRow(identifier: identifier, values: filteredRow);
    }).toList();

    return rows;
  }

  @override
  List<DbRow<RowIdentifier>> getRows(String tableName, int limit, int offset) {
    final result = db.select(
      "SELECT rowid AS _rowid_, * FROM  LIMIT ? OFFSET ?",
      [limit, offset],
    );

    return _convertToDbRow(result);
  }

  @override
  List<DbRow> getRowsOrderedBy(
    String tableName,
    int limit,
    int offset,
    String orderColumn,
  ) {
    final result = db.select(
      "SELECT * FROM $tableName ORDER BY $orderColumn DESC LIMIT ? OFFSET ?",
      [limit, offset],
    );

    return _convertToDbRow(result);
  }

  @override
  void deleteRowByRowID({
    required String tableName,
    required SqliteRowIdentifier id,
  }) {
    db.execute('DELETE FROM $tableName WHERE ${id.name} = ?', [id.value]);
  }

  @override
  void updateRow({
    required String tableName,
    required DbRow<SqliteRowIdentifier> row,
  }) {
    final SqliteRowIdentifier identifier = row.identifier;
    final record = update.generate(
      tableName,
      row.values,
      identifier.name,
      identifier.value,
    );
    final sql = record.sql;
    final updateValues = record.data;

    PreparedStatement? stmt;

    try {
      // Begin transaction
      db.execute('BEGIN;');

      // Prepare & execute statement
      stmt = db.prepare(sql);
      stmt.execute(updateValues);

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
  void deleteRow({required String tableName, required DbRow row}) {
    PreparedStatement? stmt;

    final rowid = row["_rowid_"];

    if (rowid == null) {
      throw Exception(
        "_rowid_ column is null. Cannot delete or update rows without rowid enabled.",
      );
    }

    try {
      stmt = db.prepare('DELETE FROM $tableName WHERE rowid = ?;');
      stmt.execute([rowid]);
    } catch (error) {
      rethrow;
    } finally {
      stmt?.dispose();
    }
  }
}
