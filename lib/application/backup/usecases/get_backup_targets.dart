import 'package:ui_prototype/application/backup/interfaces/drive_selection_repo.dart';

class GetBackupTargets {
  final DriveSelectionRepository repo;

  GetBackupTargets(this.repo);

  Future<Set<String>> execute() async {
    return repo.loadSelectedIds();
  }

}