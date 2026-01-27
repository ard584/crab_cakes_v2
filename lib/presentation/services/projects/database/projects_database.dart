import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'projects_database.g.dart';

class Projects extends Table {
  BlobColumn get id => 
    blob().customConstraint('NOT NULL CHECK(length(id) = 16)')();

  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BlobColumn get createdByDevice => 
    blob().customConstraint('NOT NULL CHECK(length(created_by_device) = 16)')();
  BlobColumn get updatedByDevice => 
    blob().customConstraint('NOT NULL CHECK(length(updated_by_device) = 16)')();
  TextColumn get dbPath => text().unique()();

  @override
  Set<Column> get primaryKey => {id};

}

@DriftDatabase(tables: [Projects])
class AppDatabase extends _$AppDatabase {
  // After generating code, this class needs to define a `schemaVersion` getter
  // and a constructor telling drift where the database should be stored.
  // These are described in the getting started guide: https://drift.simonbinder.eu/setup/
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 1;

}

  QueryExecutor openConnection() {
    return driftDatabase(
      name: 'projects_database',
      native: const DriftNativeOptions(
        // By default, `driftDatabase` from `package:drift_flutter` stores the
        // database files in `getApplicationDocumentsDirectory()`.
        databaseDirectory: getApplicationSupportDirectory,
      ),
      // If you need web support, see https://drift.simonbinder.eu/platforms/web/
    );
  }