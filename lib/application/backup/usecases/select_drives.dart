import 'package:crab_cakes/application/backup/interfaces/drive_selection_repo.dart';

class SelectDrives {
  final DriveSelectionRepository repo;

  SelectDrives(this.repo);
  
  Future<void> call(Set<String> ids) => repo.saveSelectedIds(ids);
}