import 'package:ui_prototype/application/interfaces/project_database.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

class SaveTable {
  final ProjectDatabase db;

  SaveTable(this.db);

  Future<void> call(TableInput table) {
    return db.saveTable(table);
  }
}