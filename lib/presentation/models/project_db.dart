import 'package:ui_prototype/presentation/models/table.dart';

class ProjectDb {

  final Map<String, TableModel> tables;

  const ProjectDb({
    required this.tables,
  });

@override
String toString() {
  if (tables.isEmpty) return 'ProjectDb: (Empty)';

  final buffer = StringBuffer();
  buffer.writeln('====================================');
  buffer.writeln('PROJECT DATABASE (${tables.length} Tables)');
  buffer.writeln('====================================');

  for (final table in tables.values) {
    buffer.writeln(table);
    buffer.writeln('------------------------------------');
  }

  return buffer.toString();
}

}