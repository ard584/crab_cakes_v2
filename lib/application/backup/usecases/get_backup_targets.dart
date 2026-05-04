import 'package:crab_cakes/application/backup/interfaces/drive_selection_repo.dart';

class GetBackupTargets {
  final DriveSelectionRepository repo;

  GetBackupTargets(this.repo);

  Future<Set<String>> execute() async {
    return repo.loadSelectedIds();
  }

}