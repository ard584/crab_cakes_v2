class SQLInsertGenerator {

  bool _isValid(dynamic value) {
    if (value == null) return false;
    if (value is String && value.isEmpty) return false;
    return true;
  }

  Map<String, dynamic> _filterValues(Map<String, dynamic> values) {
    final map = <String, dynamic>{};

    for (final value in values.entries) {
      if (_isValid(value.value)) {
        map[value.key] = value.value;
      }
    }

    return map;
  }

  List<dynamic> generateValues(Map<String, dynamic> values) {
    final filtered = _filterValues(values);
    return filtered.values.toList();
  }

  String generateInsertStatement({
    required String tableName,
    required Map<String, dynamic> values,
  }) {
    final filtered = _filterValues(values);

    print("FILTERED: $filtered");

    final columns = filtered.keys.join(', ');
    final placeholders = List.filled(filtered.length, '?').join(', ');

    return "INSERT INTO $tableName ($columns) VALUES ($placeholders)";
  }
}
