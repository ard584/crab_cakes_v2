import 'package:pluto_grid/pluto_grid.dart';
import 'package:ui_prototype/application/project/use_cases/delete_rows.dart';
import 'package:ui_prototype/domain/db_table.dart';
import 'package:ui_prototype/presentation/adapters/pluto_grid_adapter.dart';

class PlutoDeleteRowsController {
  final DeleteRowsUseCase useCase;

  PlutoDeleteRowsController({required this.useCase});

  void deleteFromPluto({required List<PlutoRow> rows, required DbTable table}) {
    // Get dbRows from PlutoRows
    final identifiers = extractIdentifiers(rows);

    useCase.call(tableName: table.name, identifiers: identifiers);
  }
}
