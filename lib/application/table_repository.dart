import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/domain/models/db_row.dart';

abstract interface class ActiveProjectRepository {

  // Loads the columns from the table
  DbTable getTableSchema(String tableName);

  // Load rows
  List<DbRow> getRows(String tableName, int limit, int offset);
  List<DbRow> getAllRows(String tableName);
  List<DbRow> getRowsOrdered(String tableName, int limit, int offset);
  List<DbRow> getRowsOrderedId(String tableName, int limit, int offset);

  // Saves the current table
  void insertRow({required String tableName, required Map<String, dynamic> values});

  // Updates row
  void updateRow({required String tableName, required DbRow row, required String id, required String idValue});

  // Deletes row
  void deleteRow({required String tableName, required DbRow row});
}