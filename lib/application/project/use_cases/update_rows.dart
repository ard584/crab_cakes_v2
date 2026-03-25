import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';
import 'package:ui_prototype/domain/models/db_row.dart';

class UpdateRowsUseCase<TIdentifier extends RowIdentifier> {
  final ActiveProjectRepository repo;

  UpdateRowsUseCase({required this.repo});

  void call({required String tableName, required List<DbRow<TIdentifier>> rows}) {
    for (final row in rows) {
      repo.updateRow(tableName: tableName, row: row);
    }
  }
}