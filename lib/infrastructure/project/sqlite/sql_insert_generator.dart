import 'package:ui_prototype/presentation/view_models/project_input.dart';

class SQLInsertGenerator {

  // TODO: This should not rely on the viewModels, find a way to abstract this away
  final TableInput table;

  SQLInsertGenerator({required this.table}) {

    // Check if tableName exists in project
  }

  String _generateColumns() {
    String columns = table.attributes.keys.map((key) => "'$key'").join(', ');
    return columns;
  }

  String _generatePlaceholders() {
    int placeholderCount = table.attributes.length;
    return List.filled(placeholderCount, '?').join(', ');
  }

  String generateInsertIntoTable() {
    String columns = _generateColumns();
    String placeholders = _generatePlaceholders();

    String statement =
        "INSERT INTO ${table.name} ( $columns ) VALUES ( $placeholders )";
    return statement;
  }
}