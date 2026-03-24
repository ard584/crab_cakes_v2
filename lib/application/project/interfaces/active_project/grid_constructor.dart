import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';
import 'package:ui_prototype/domain/models/db_row.dart';

abstract class GridConstructor<TWidget, TRow, TColumn, TCallback> {

  List<TColumn> constructColumns(DbTable table);
  TRow constructRow<T extends RowIdentifier>(DbTable table, DbRow<T> row);
  TWidget constructGrid({
    required List<TRow> rows,
    required List<TColumn> columns,
    TCallback? onChanged
  });
  
}