import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/application/project/use_cases/update_rows.dart';
import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/domain/models/db_row.dart';
import 'package:ui_prototype/presentation/adapters/pluto_grid_adapter.dart';

class PlutoUpdateRowsController {
  final UpdateRowsUseCase useCase;

  PlutoUpdateRowsController({required this.useCase});

  void updateFromPluto({required List<PlutoRow> rows, required DbTable table}) {

    // Extract names from DbTable
    final Set<String> columnNames = table.columns.map((column) {
      return column.name;
    }).toSet();

    final List<DbRow> dbRows = rows.map((row) {
      return PlutoRowMapper.toDbRow(row: row, dbColumnNames: columnNames);
    }).toList();

    print("DBROWS: $dbRows");

    // Call use case
    useCase.call(tableName: table.name, rows: dbRows);
  }

}
