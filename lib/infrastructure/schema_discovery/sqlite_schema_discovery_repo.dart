import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/schema_discovery/interfaces/schema_discovery_repo.dart';

class SqliteSchemaDiscoveryRepo implements SchemaDiscoveryRepo {

  final Database db;

  const SqliteSchemaDiscoveryRepo(this.db);
  
  @override
  Future<List<String>> getTables() async {
    final result = db.select('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
        AND name != '__project_settings'
      ORDER BY name
    ''');

    return result.map((row) => row['name'] as String).toList();

  }

  @override
  Future<List<String>> getColumns(String table) async {
    final result = db.select('PRAGMA table_info($table)');

    return result.map((row) => row['name'] as String).toList();
  }
}