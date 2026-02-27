import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'backup_settings_db.g.dart';

// 1) Table
class SelectedBackupTargets extends Table {
  TextColumn get targetId => text()();

  @override
  Set<Column> get primaryKey => {targetId};
}

// 2) Database
@DriftDatabase(tables: [SelectedBackupTargets])
class BackupSettingsDb extends _$BackupSettingsDb {
  BackupSettingsDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// 3) Executor / file location 
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'backup_settings.sqlite'));
    return NativeDatabase(file);
  });
}