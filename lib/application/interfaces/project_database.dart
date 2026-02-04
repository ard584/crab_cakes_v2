import 'package:ui_prototype/presentation/view_models/project_input.dart';

// Abstract interface for interacting with active project's database
abstract class ProjectDatabase {
  Future<void> saveTable(TableInput project);
}