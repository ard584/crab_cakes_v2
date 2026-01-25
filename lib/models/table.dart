import 'attribute.dart';

class TableModel {
  final String name;
  final AttributeList attributes;

  TableModel({required this.name, required List<Attribute> attributeList})
    : attributes = AttributeList(attributeList); // Instantiate the new class

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Table: $name');
    for (final attr in attributes) {
      // Indent attributes by 2 spaces for readability
      buffer.writeln('  - $attr');
    }
    return buffer.toString().trimRight();
  }
}
