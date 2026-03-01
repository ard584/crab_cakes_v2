class Attribute {
  // Define data types
  final int columnID;
  final String name;
  final String dataType;
  final bool isNotNullable;
  final String? defaultValue;
  final bool isPrimaryKey;

  // Define initializer
  Attribute({
    required this.columnID,
    required this.name,
    required this.dataType,
    required this.isNotNullable,
    this.defaultValue,
    required this.isPrimaryKey,
  });

  @override
  String toString() {
    return 'Attribute('
        'columnID: $columnID, '
        'name: $name, '
        'dataType: $dataType, '
        'isNotNullable: $isNotNullable, '
        'defaultValue: $defaultValue, '
        'isPrimaryKey: $isPrimaryKey'
        ')';
  }
}

// Define class for attribute list
class AttributeList extends Iterable<Attribute> {
  // Define map of attributes
  final Map<String, Attribute> _attributes;

  // Format list of attributes into map (key is attribute name)
  AttributeList(List<Attribute> attributeList)
    : _attributes = {for (var attr in attributeList) attr.name: attr};

  // Define custom map getter
  Map<String, Attribute> get asMap => _attributes;

  @override
  Iterator<Attribute> get iterator => _attributes.values.iterator;

  @override
  int get length => _attributes.length;

  // Allow getter for specific attribute
  Attribute? operator [](String name) => _attributes[name];

  // Custom string formatting
  @override
  String toString() {
    // Check if attributes exists or not
    if (_attributes.isEmpty) {
      // Return empty array
      return '[]';
    }

    // Iterates over the attributes and creates a formatted string for each
    final attributesString = _attributes.values
        .map((attr) {
          // define strings for constraints
          final notNull = attr.isNotNullable ? 'NOT NULL' : '';
          final primaryKey = attr.isPrimaryKey ? 'PK' : '';
          final defaultValue = attr.defaultValue != null
              ? 'DEFAULT ${attr.defaultValue}'
              : '';

          // Join constraints into single strong
          final constraints = [
            primaryKey,
            notNull,
            defaultValue,
          ].where((s) => s.isNotEmpty).join(' ');

          return '''  [${attr.columnID.toString().padLeft(2).padRight(3)}]: ${attr.name.padRight(15)} | Type: ${attr.dataType.padRight(12)} | Constraints: $constraints''';
        })
        .join('\n');

    return '[\n$attributesString\n]';
  }
}
