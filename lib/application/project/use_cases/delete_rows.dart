import 'package:crab_cakes/application/active_project_repository.dart';
import 'package:crab_cakes/domain/entities/row_identifier.dart';

class DeleteRowsUseCase {
  final ActiveProjectRepository repo;

  DeleteRowsUseCase({required this.repo});

  void call({required String tableName, required List<RowIdentifier> identifiers}) {
    for (final id in identifiers) {
      repo.deleteRowByRowID(tableName: tableName, id: id);
    }
  }
}