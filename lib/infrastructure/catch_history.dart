import 'package:ui_prototype/application/active_project_repository.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

class CatchHistoryViewModel {
  final ActiveProjectRepository<RowIdentifier> db;
  final TableInput table;

  CatchHistoryViewModel({required this.db, required this.table});

  // Column names derived from the table definition
  List<String> get _tableColumns => table.attributes.keys.toList();

// get the map of the recent saves, fill with empty if less than 5 entries
  List<Map<String, dynamic>> getCatchMap() {
    List<Map<String, dynamic>> catches = getCatches();
    final int columnCount = catches.isNotEmpty
        ? catches[0].keys.length
        : _tableColumns.length;

    while (catches.length < 5) {
      final Map<String, dynamic> emptyMap = {
        for (int i = 0; i < columnCount; i++) getColumnName(i): '',
      };
      catches.add(emptyMap);
    }

    return catches;
  }

// get column names to be dispalyed
  String getColumnName(int index) {
    final catches = getCatches();
    final keys = catches.isNotEmpty
        ? catches[0].keys.toList()
        : _tableColumns;

    if (index < 0 || index >= keys.length) return 'unknown';
    return keys[index];
  }

// get most recent 5 catches
  List<Map<String, dynamic>> getCatches() {
    final schema = db.getTableSchema(table.name);
    final hasCreatedAt = schema.columns.any(
      (col) => col.name.toLowerCase() == 'created_at_time'
    );

  final orderColumn = hasCreatedAt ? 'created_at_time' : 'rowid';
  final rows = db.getRowsOrderedBy(table.name, 5, 0, orderColumn);

    return rows.map((row) => row.values).toList();
  }
  
// Get number of columns max of 8
  int getColumnCount() {
    final catches = getCatches();
    final count = catches.isNotEmpty ? catches[0].keys.length : _tableColumns.length;
    return count > 8 ? 8 : count;
  }

// get character width of column data to ensure they fit
  double getColumnWidth(int columnIndex) {
    final catches = getCatchMap();

    double maxWidth = getColumnName(columnIndex).length.toDouble();

    for (final row in catches) {
      final value = row[row.keys.elementAt(columnIndex)].toString();
      final width = value.length.toDouble();
      if (width > maxWidth) maxWidth = width;
    }

    return (maxWidth * 10.0) + 24;
  }
}