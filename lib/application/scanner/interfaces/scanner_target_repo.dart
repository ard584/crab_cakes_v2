abstract class ScannerTargetRepo {
  Future<void> selectTable(String name);

  Future<void> selectColumn(String name);
}