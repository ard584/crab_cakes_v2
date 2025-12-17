import 'attribute.dart';

class TableModel {
  final String name;
  final AttributeList attributes;

  TableModel({
    required this.name,
    required List<Attribute> attributeList, 
  }) : attributes = AttributeList(attributeList); // Instantiate the new class

@override
String toString() {
  String attrString = 'Table: $name\nAttributes: (';

  // Access the map through the 'map' getter
  attrString += attributes.map.entries.map((attribute) {
      // 'attribute' is now a MapEntry
      return '${attribute.value.columnID}: ${attribute.value.name}';
  }).join(', ');

  attrString += ')';

  return attrString;
}
}