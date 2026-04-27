import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';
import 'package:ui_prototype/domain/models/db_row.dart';
// import 'package:ui_prototype/domain/models/db_row.dart';

List<RowIdentifier> extractIdentifiers(List<PlutoRow> rows) {
  final List<RowIdentifier> identifiers = [];

  for (final row in rows) {
    print("ROW KEY: ${row.key}");
    identifiers.add((row.key as ValueKey<RowIdentifier>).value);
  }

  return identifiers;
}

PlutoRow? extractPlutoRowByKey(Key key, PlutoGridStateManager stateManager) {
  return stateManager.refRows.firstWhere((row) => row.key == key);
}

List<PlutoRow> extractPlutoRowsByKeys(
  List<Key> keys,
  PlutoGridStateManager stateManager,
) {
  final rows = stateManager.refRows;
  return rows.where((row) => keys.contains(row.key)).toList();
}

class PlutoRowMapper {
  static DbRow<SqliteRowIdentifier> toDbRow({
    required PlutoRow row,
    required Set<String> dbColumnNames,
  }) {
    // Extract RowIdentifier
    final key = (row.key as ValueKey).value;
    final identifier = key as SqliteRowIdentifier;

    final Map<String, dynamic> values = {};

    // Filter non-database values out
    for (final cell in row.cells.entries) {
      if (dbColumnNames.contains(cell.key)) {
        values[cell.key] = cell.value.value;
      }
    }

    return DbRow(identifier: identifier, values: values);
  }
}
