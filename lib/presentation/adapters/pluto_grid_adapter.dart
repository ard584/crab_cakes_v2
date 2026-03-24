import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';
// import 'package:ui_prototype/domain/models/db_row.dart';

List<RowIdentifier> extractIdentifiers(List<PlutoRow> rows) {
  final List<RowIdentifier> identifiers = [];

  for (final row in rows) {
    print("ROW KEY: ${row.key}");
    identifiers.add((row.key as ValueKey<RowIdentifier>).value);
  }

  return identifiers;
}

// List<DbRow> extractDbRows(List<PlutoRow> rows) {
//   final List<DbRow> dbRows = [];

//   for (final row in rows) {
//     dbRows.add((row.key as ValueKey<DbRow>).value);
//   }

//   return dbRows;
// }

// PlutoRow? extractPlutoRowByKey(Key key, PlutoGridStateManager stateManager) {
//   return stateManager.refRows.firstWhere((row) => row.key == key);
// }

// List<PlutoRow> extractPlutoRowsByKeys(
//   List<Key> keys,
//   PlutoGridStateManager stateManager,
// ) {
//   final rows = stateManager.refRows;
//   return rows.where((row) => keys.contains(row.key)).toList();
// }

// DbRow convertPlutoRowToDbRow(PlutoRow row) {
//   final Map<String, dynamic> values = {};

//   row.cells.forEach((key, cell) {
//     values[key] = cell.value;
//   });

//   return DbRow(values: values);
// }

// List<DbRow> convertPlutoRowsToDbRows(List<PlutoRow> rows) {

//   // Extract dbRows

//   return rows.map((row) {
//     return convertPlutoRowToDbRow(row);
//   }).toList();
// }
