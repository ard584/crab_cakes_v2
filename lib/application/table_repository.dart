import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';
import 'package:ui_prototype/domain/models/db_row.dart';

abstract interface class ActiveProjectRepository<TIdentifier extends RowIdentifier> {

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
  void updateRow({required String tableName, required DbRow<TIdentifier> row});

  // Deletes row
  void deleteRow({required String tableName, required DbRow row});
  void deleteRowByRowID({required String tableName, required TIdentifier id});
}