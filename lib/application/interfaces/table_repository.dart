import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/presentation/view_models/db_table_view_model.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

abstract interface class TableRepository {

  // Loads the columns from the table
  DbTable getTableSchema(String tableName);

  // Load rows
  List<DbRow> getRows(String tableName, int limit, int offset);
  List<DbRow> getAllRows(String tableName);

  // Saves the current table
  void saveTable(TableInput table);
}