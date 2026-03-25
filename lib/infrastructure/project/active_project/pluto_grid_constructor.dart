import 'package:flutter/foundation.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/application/project/interfaces/active_project/grid_constructor.dart';
import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';
import 'package:ui_prototype/domain/models/db_row.dart';

class PlutoGridConstructor
    implements
        GridConstructor<
          PlutoGrid,
          PlutoRow,
          PlutoColumn,
          PlutoOnChangedEventCallback,
          SqliteRowIdentifier
        > {
  @override
  List<PlutoColumn> constructColumns(DbTable table) {
    // Define list of pluto columns
    List<PlutoColumn> columns = [];

    // Iterate through DbTable
    for (final column in table.columns) {
      // Get type of current column
      final PlutoColumnType type;

      // Switch case to get correct PlutoColumn type
      switch (column.type) {
        // Integer
        case "INTEGER":
          type = PlutoColumnType.number(negative: false);
          break;

        // Real
        case "REAL":
          type = PlutoColumnType.number(format: "#,###.###");

        // Default (text)
        default:
          type = PlutoColumnType.text();
      }

      // Construct field
      final String field = _getFieldName(table.name, column.name);

      // Construct title
      final String title = column.name;

      // Construct PlutoColumn
      final col = PlutoColumn(title: title, field: field, type: type);

      // Append to columns array
      columns.add(col);
    }

    return columns;
  }

  @override
  constructGrid({
    required List<PlutoRow> rows,
    required List<PlutoColumn> columns,
    onChanged,
  }) {
    return PlutoGrid(columns: columns, rows: rows, onChanged: onChanged);
  }

  String _getFieldName(String tableName, String columnName) {
    return columnName;
  }

  @override
  constructRow(DbTable table, DbRow row) {

    // Extract RowIdentifier
    final id = row.identifier;
    
    // Define PlutoRow
    final PlutoRow plutoRow = PlutoRow(
      cells: {},
      key: ValueKey(id),
    );

    // Iterate through row
    for (final cell in row.values.entries) {
      // Match pluto field name
      final String fieldName = _getFieldName(table.name, cell.key);

      // Create PlutoCell
      final plutoCell = PlutoCell(value: cell.value);

      // Add to plutoRow
      plutoRow.cells[fieldName] = plutoCell;
    }

    // Return PlutoRow
    return plutoRow;
  }
}
