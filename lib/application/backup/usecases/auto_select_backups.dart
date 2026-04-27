import 'package:ui_prototype/application/backup/interfaces/drive_discovery.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_selection_repo.dart';
//import 'package:ui_prototype/application/backup/dtos/backup_target.dart';

class AutoSelectBackups {
  final DriveDiscovery discoverer;
  final DriveSelectionRepository selectionRepo;

  AutoSelectBackups(this.discoverer, this.selectionRepo);

  Future<void> execute() async {
    //discover connected drives, convert to list of strings 
    final driveList = await discoverer.discover();
    final Set<String> driveIdList = driveList.map((drive)=>drive.id).toSet();

    //select that list of targets
    await selectionRepo.saveSelectedIds(driveIdList);
  }

}