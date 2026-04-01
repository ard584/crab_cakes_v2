import 'package:ui_prototype/application/backup/interfaces/drive_selection_repo.dart';

class DummyDriveSelectionRepo implements DriveSelectionRepository {

  @override
  Future<Set<String>> loadSelectedIds() async {
    return {};
  }

  @override
  Future<void> saveSelectedIds(Set<String> ids) async {
    throw UnsupportedError('Backup is only supported on Windows right now.');
  }

}