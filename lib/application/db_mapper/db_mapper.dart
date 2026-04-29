import 'package:ui_prototype/domain/models/project_db.dart';

abstract class DbMapper<TDatabase> {
  ProjectDb mapDB(TDatabase db);
}