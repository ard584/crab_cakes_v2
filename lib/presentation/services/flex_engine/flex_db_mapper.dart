import 'package:sqlite3/sqlite3.dart';
import 'package:crab_cakes/domain/models/project_db.dart';
import 'package:crab_cakes/presentation/services/flex_engine/creation/project_db_mapper.dart';

class FlexDbMapper {

  final Database db;

  FlexDbMapper({required this.db});

  ProjectDb mapFromDatabase() {

    final projectDb = createDbObject(db);
    return projectDb;
  }
}
