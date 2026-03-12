import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/domain/models/db_row.dart';

List<DbRow> extractDbRows(List<PlutoRow> rows) {
  final List<DbRow> dbRows = [];

  for (final row in rows) {
    dbRows.add((row.key as ValueKey<DbRow>).value);
  }

  return dbRows;
}