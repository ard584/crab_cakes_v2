import 'package:ui_prototype/domain/db_table.dart';

class DbTableViewModel {
  final DbTable table;
  final List<DbRow> _rows = [];
  int selectedRowIndex = -1;

  DbTableViewModel({
    required this.table
  });

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

  // Getter functions
  DbRow rowAt(int rowIndex) => _rows[rowIndex];
  Object? cellAt(int rowIndex, int colIndex) => _rows[rowIndex][colIndex];
  Object? valueAt(int rowIndex, String colName) {
    final colIndex = table.columnIndexByName(colName);

    if (colIndex == -1) {
      throw Exception("Column '$colName' not found in DbTable");
    }
    return _rows[rowIndex][colIndex];
  }

  
}

class DbRow {
  final DbTable table;
  final List<Object?> values;

  DbRow({required this.table, required this.values});

  // Lets us access values without doing row.values, makes it cleaner
  Object? operator [](int columnIndex) => values[columnIndex];

}