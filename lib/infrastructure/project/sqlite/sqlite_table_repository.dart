import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/interfaces/table_repository.dart';
import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/presentation/view_models/db_table_view_model.dart';

class SqliteTableRepository implements TableRepository {
  final Database db;

  SqliteTableRepository({required this.db});

  @override
  Future<DbTable> loadTableSchema(String tableName) async {
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
  Future<DbTableViewModel> loadAllRows(String tableName) {
    // TODO: implement loadAllRows
    throw UnimplementedError();
  }

  @override
  Future<DbTableViewModel> loadRows(String tableName, int limit, int offset) {
    // TODO: implement loadRows
    throw UnimplementedError();
  }
}
