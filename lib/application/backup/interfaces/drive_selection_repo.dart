abstract class DriveSelectionRepository {

  Future<Set<String>> loadSelectedIds();

  Future<void> saveSelectedIds( Set<String> ids);
}