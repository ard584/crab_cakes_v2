enum DataType { integer, decimal, text, binary, boolean, datetime, unknown }

// This is a model for a table in the database
// It holds immutable data about the table, such as the name,
// and a list of column objects

class DbTable {
  final String name;
  final List<DbColumn> columns;

  late Map<String, int> _columnIndex;

  DbTable({required this.name, required this.columns}) {
    // Creates map to get column's index from the column name
    for (int i = 0; i < columns.length; i++) {
      // Key is the column name
      // Index is the value
      _columnIndex[columns[i].name] = i;
    }
  }

  // Column getters
  DbColumn columnAt(int colIndex) => columns[colIndex];

  DbColumn columnByName(String colName) {
    final colIndex = _columnIndex[colName];

    if (colIndex == null) {
      throw Exception("Column not found: $colName");
    }
    return columns[colIndex];
  }

  int columnIndexByName(String colName) {
    final colIndex = _columnIndex[colName];

    if (colIndex == null) return -1;

    return colIndex;
  }

  int get columnCount => columns.length;
}

class DbColumn {
  // Needs to store data type
  final DataType type;

  final String name;

  // These are features of most databases, so safe to have in domain
  final bool nullable;
  final bool primaryKey;

  DbColumn({
    required this.name,
    required this.type,
    required this.nullable,
    required this.primaryKey,
  });
}
