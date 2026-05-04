import 'package:crab_cakes/application/active_project_repository.dart';
import 'package:crab_cakes/domain/entities/row_identifier.dart';
import 'package:crab_cakes/domain/models/db_row.dart';

class UpdateRowsUseCase<TIdentifier extends RowIdentifier> {
  final ActiveProjectRepository repo;

  UpdateRowsUseCase({required this.repo});

  void call({required String tableName, required List<DbRow<TIdentifier>> rows}) {
    for (final row in rows) {
      repo.updateRow(tableName: tableName, row: row);
    }
  }
}