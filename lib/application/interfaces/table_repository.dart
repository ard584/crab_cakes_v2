import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/presentation/view_models/db_table_view_model.dart';

abstract class TableRepository {

  // Loads the columns from the table
  Future<DbTable> loadTableSchema(String tableName);

  // Load rows
  Future<DbTableViewModel> loadRows(String tableName, int limit, int offset);
  Future<DbTableViewModel> loadAllRows(String tableName);
}