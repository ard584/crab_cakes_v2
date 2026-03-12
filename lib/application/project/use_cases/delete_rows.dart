import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/domain/models/db_row.dart';

class DeleteRowsUseCase {
  final ActiveProjectRepository repo;

  DeleteRowsUseCase({required this.repo});

  void call({required String tableName, required List<DbRow> rows}) {
    for (final row in rows) {
      repo.deleteRow(tableName: tableName, row: row);
    }
  }
}