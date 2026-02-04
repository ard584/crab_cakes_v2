import 'package:ui_prototype/application/interfaces/project_database.dart';
import 'package:ui_prototype/infrastructure/project/sqlite/sql_insert_generator.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';

class SqliteProjectDatabase implements ProjectDatabase {

  @override
  Future<void> saveTable(TableInput table) {
    // TODO: implement save

    // Call insert generator
    final statement = SQLInsertGenerator(table: table).generateInsertIntoTable();
    print("Statement: $statement");
    

    // Wrap in transaction

    // Run on db
    throw UnimplementedError();
  }
}