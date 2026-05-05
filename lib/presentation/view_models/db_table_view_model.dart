import 'package:crab_cakes/domain/db_table.dart';
import 'package:crab_cakes/domain/models/db_row.dart';

class DbTableViewModel {
  final DbTable table;
  final List<DbRow> _rows = [];
  int selectedRowIndex = -1;

  DbTableViewModel({required this.table});

  // Unmutatable getter function
  List<DbRow> get rows => List.unmodifiable(_rows);
  int get rowCount => _rows.length;

  // Mutator functions
  void addRows(List<DbRow> rows) {
    _rows.addAll(rows);
  }

  void clearRows() {
    _rows.clear();
  }

  List<String> get columnNames => table.columns.map((c) => c.name).toList();

  bool hasColumn(String name) {
    final columns = table.columns;
    return columns.any((col) => col.name == name);
  }

  // Getter functions
  DbRow rowAt(int rowIndex) => _rows[rowIndex];
  Object? cellAt(int rowIndex, int colIndex) {
    final columnName = table.columns[colIndex].name;
    return _rows[rowIndex][columnName];
  }

  Object? valueAt(int rowIndex, String colName) {
    if (!hasColumn(colName)) {
      throw Exception("Column '$colName' not found in DbTable");
    }

    return _rows[rowIndex][colName];
  }
}
