import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/domain/models/db_row.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

class SaveTable {
  final ActiveProjectRepository db;

  SaveTable(this.db);

  List<DbRow>? call(TableInput table, {int? limit, int? offset}) {
    final String tableName = table.name;
    final Map<String, dynamic> values = table.toValueMap();

    db.insertRow(tableName: tableName, values: values);

    if (limit != null) {
      
      final result = db.getRows(tableName, limit, offset ?? 0);

      return result;
    }

    return null;
  }
}
