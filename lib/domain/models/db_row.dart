class DbRow {
  final Map<String, dynamic> values;

  DbRow({required this.values});

  Object? operator [](String columnName) => values[columnName];

  @override
  String toString() {
    String string = "DbRow (\n";

    for (final value in values.entries) {
      string += "  [${value.key}: ${value.value}]\n";
    }

    string += ")";

    return string;
  }
}