import 'package:ui_prototype/presentation/view_models/project_input.dart';

class SQLInsertGenerator {
  // TODO: This should not rely on the viewModels, find a way to abstract this away
  final TableInput table;

  SQLInsertGenerator({required this.table});

  List<AttributeFormField> _getActiveColumns() {
    final List<AttributeFormField> activeColumns = [];

    for (final attribute in table.attributes.values) {
      if (attribute.controller.text.isNotEmpty) {
        activeColumns.add(attribute);
      }
    }

    return activeColumns;
  }

  String _generateColumns() {
    final activeColumns = _getActiveColumns();

    String columns = activeColumns
        .map((column) {
          return column.fields.name;
        })
        .join(', ');

    return columns;
  }

  String _generatePlaceholders() {
    final activeColumns = _getActiveColumns();

    int placeholderCount = activeColumns.length;
    return List.filled(placeholderCount, '?').join(', ');
  }

  List<String> generateValues() {
    final activeColumns = _getActiveColumns();

    final values = activeColumns.map((attribute) {
      return attribute.controller.text;
    }).toList();

    return values;
  }

  String generateInsertIntoTable() {
    String columns = _generateColumns();
    String placeholders = _generatePlaceholders();

    String statement =
        "INSERT INTO ${table.name} ( $columns ) VALUES ( $placeholders )";
    return statement;
  }
}
