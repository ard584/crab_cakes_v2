import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/domain/models/db_row.dart';

class UpdateRowsUseCase {
  final ActiveProjectRepository repo;

  UpdateRowsUseCase({required this.repo});

  void call({required String tableName, required List<DbRow> rows, required String id, required String idValue}) {
    for (final row in rows) {
      repo.updateRow(tableName: tableName, row: row, id: id, idValue: idValue);
    }
  }
}