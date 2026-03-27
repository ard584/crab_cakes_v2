abstract class RowIdentifier {
  get identifier;
}

class SqliteRowIdentifier implements RowIdentifier {

  // Name is for the name of the column
  // Key is for the value
  final String name;
  final dynamic value;

  SqliteRowIdentifier({required this.name, required this.value});

  @override
  ({String name, dynamic value}) get identifier {
    // Create immutable named record type
    return (name: name, value: value);
  }

  @override
  String toString() {
    return "name: $name, value: $value";
  }
}
