import 'package:crab_cakes/domain/entities/row_identifier.dart';

class DbRow<T extends RowIdentifier> {
  final Map<String, dynamic> values;
  final T identifier;

  DbRow({required this.identifier, required this.values});

  Object? operator [](String columnName) => values[columnName];

  @override
  String toString() {
    String string = "DbRow (\n"
    "RowIdentifier: $identifier \n";
    for (final value in values.entries) {
      string += "  [${value.key}: ${value.value}]\n";
    }
    string += ")";

    return string;
  }
}