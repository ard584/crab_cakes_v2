import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';
import 'package:ui_prototype/infrastructure/providers/column_filter_provider.dart';
import 'package:ui_prototype/domain/entities/settings/project_settings.dart';

class CatchHistoryViewModel {
  final ActiveProjectRepository db;
  final TableInput table;
  final ProjectSettings? settings;
  static const int kMaxHistoryColumns = 8;

  CatchHistoryViewModel({required this.db, required this.table, this.settings,});

  List<String> get _allAvailableColumns {
    return table.attributes.keys.where((col) => !col.startsWith(kColumnPrefixToHide)).toList();
  }

  // Get columns selected for catch history from settings
  List<String> get _selectedColumnsForCatchHistory {
    // Default to first 8 columns
    final defaultColumns = _allAvailableColumns.take(kMaxHistoryColumns).toList();
    
    // If no settings, use default
    if (settings == null) {
      return defaultColumns;
    }
    
    try {
      final selected = <String>[];
      
      for (final columnName in _allAvailableColumns) {
        final config = settings!.fieldConfig.getConfig(
          table: table.name,
          col: columnName,
        );
        
        // Add if showInCatchHistory is true
        if (config?.showInCatchHistory == true) {
          selected.add(columnName);
        }
      }
      
      // If nothing selected, return default
      if (selected.isEmpty) {
        return defaultColumns;
      }
      
      // Return selected columns
      return selected.take(kMaxHistoryColumns).toList();
      
    } catch (e) {
      return defaultColumns;
    }
  }

  List<String> get _tableColumns => _selectedColumnsForCatchHistory;

// get the map of the recent saves, fill with empty if less than 5 entries
  List<Map<String, dynamic>> getCatchMap() {
    List<Map<String, dynamic>> catches = getCatches();
    final displayColumns = _tableColumns;

    while (catches.length < 5) {
      final Map<String, dynamic> emptyMap = {
        for (final col in displayColumns) col: '',
      };
      catches.add(emptyMap);
    }

    return catches;
  }

// get column names to be displayed
  String getColumnName(int index) {
    final displayColumns = _tableColumns;

    if (index < 0 || index >= displayColumns.length) return 'unknown';
    return displayColumns[index];
  }

// get most recent 5 catches
  List<Map<String, dynamic>> getCatches() {
    final schema = db.getTableSchema(table.name);
    final hasCreatedAt = schema.columns.any(
      (col) => col.name.toLowerCase() == '${kColumnPrefixToHide}created_at_time'
    );

    final orderColumn = hasCreatedAt ? '${kColumnPrefixToHide}created_at_time' : 'rowid';
    final rows = db.getRowsOrderedBy(table.name, 5, 0, orderColumn);

    final displayColumns = _tableColumns.toSet();

  // Filter rows to only include selected columns
    return rows.map((row) {
      final filteredValues = <String, dynamic>{};
      for (final col in displayColumns) {
        filteredValues[col] = row.values[col];
      }
      return filteredValues;
    }).toList();
  }

  int getColumnCount() {
    return _tableColumns.length;
  }

// get character width of column data to ensure they fit
  double getColumnWidth(int columnIndex) {
    final catches = getCatchMap();
    final displayColumns = _tableColumns;

    if (columnIndex >= displayColumns.length) return 100.0;
    
    final columnName = displayColumns[columnIndex];
    double maxWidth = columnName.length.toDouble();

    for (final row in catches) {
      final value = row[columnName]?.toString() ?? '';
      final width = value.length.toDouble();
      if (width > maxWidth) maxWidth = width;
    }

    return (maxWidth * 10.0) + 24;
  }
}