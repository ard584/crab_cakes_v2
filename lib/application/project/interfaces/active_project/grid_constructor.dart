import 'package:crab_cakes/domain/db_table.dart';
import 'package:crab_cakes/domain/entities/row_identifier.dart';
import 'package:crab_cakes/domain/models/db_row.dart';

abstract class GridConstructor<TWidget, TRow, TColumn, TCallback, TIdentifier extends RowIdentifier> {

  List<TColumn> constructColumns(DbTable table);
  TRow constructRow(DbTable table, DbRow<TIdentifier> row);
  TWidget constructGrid({
    required List<TRow> rows,
    required List<TColumn> columns,
    TCallback? onChanged
  });
  
}