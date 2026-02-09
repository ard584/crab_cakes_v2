import 'package:ui_prototype/application/interfaces/table_repository.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

class SaveTable {
  final TableRepository db;

  SaveTable(this.db);

  void call(TableInput table) {
    db.saveTable(table);
  }
}
