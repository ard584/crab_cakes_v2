enum DataType { integer, decimal, text, binary, boolean, datetime, unknown }

// This is a model for a table in the database
// It holds immutable data about the table, such as the name,
// and a list of column objects

class DbTable {
  final String name;
  final List<DbColumn> columns;

  final Map<String, int> _columnIndex = {};

  DbTable({required this.name, required this.columns}) {
    // Creates map to get column's index from the column name
    for (int i = 0; i < columns.length; i++) {
      // Key is the column name
      // Index is the value
      _columnIndex[columns[i].name] = i;
    }
  }

  @override
  String toString() {

    String string = "DbTable ($name)\n(\n";

    for (final col in columns ) {
      string += "  $col";
    }

    string += ")";

    return string;
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

    if (colIndex == null) {
      throw RangeError('Column index not found for column "$colName"');
    }

    return colIndex;
  }

  int get columnCount => columns.length;
}

class DbColumn {
  // Needs to store data type
  final String type;

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

  @override
  String toString() {
    String string = "COLUMN ($name [$type]";

    if (primaryKey) string += " PK";
    if(nullable == false) string += " NOT NULL";

    string += ")\n";

    return string;
  }
}
