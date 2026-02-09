import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:drift/drift.dart';

class DriftDbSnapshotter {
  DriftDbSnapshotter(this.db);
  final GeneratedDatabase db; // your main AppDatabase type works too

  Future<String> createSnapshotFile(String directoryPath) async {
    final snapshotPath = path.join(directoryPath, 'main_snapshot.db');

    // VACUUM INTO requires dest does not exist
    final snapshotFile= File(snapshotPath);
    if (await snapshotFile.exists()) await snapshotFile.delete();

    // Escape single quotes for SQL literal
    final escaped = snapshotPath.replaceAll("'", "''");

    // Creates a consistent snapshot of the whole DB
    await db.customStatement("VACUUM INTO '$escaped'");

    return snapshotPath;
  }
}
