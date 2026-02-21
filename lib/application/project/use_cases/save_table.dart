import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

class SaveTable {
  final ActiveProjectRepository db;

  SaveTable(this.db);

  void call(TableInput table) {
    final String tableName = table.name;
    final Map<String, dynamic> values = table.toValueMap();

    db.insertRow(tableName: tableName, values: values);
  }
}
