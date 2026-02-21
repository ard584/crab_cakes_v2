class DbRow {
  final Map<String, Object?> values;

  DbRow({required this.values});

  Object? operator [](String columnName) => values[columnName];
}