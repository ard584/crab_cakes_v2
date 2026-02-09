import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/presentation/models/project_db.dart';
import 'package:ui_prototype/presentation/services/flex_engine/creation/project_db_mapper.dart';

class FlexDbMapper {

  final Database db;

  FlexDbMapper({required this.db});

  ProjectDb mapFromDatabase() {

    final projectDb = createDbObject(db);
    return projectDb;
  }
}
