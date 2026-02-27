import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_prototype/application/backup/interfaces/backup_writer.dart';

/// Writes a backup of the currently-open database to a target drive.
/// Prefer passing the *open* Database so we can create a consistent snapshot
/// even while the app is running.
class DbBackupWriter implements BackupWriter {
  DbBackupWriter({required Database? Function() getActiveDb})
      : _getActiveDb = getActiveDb;

  final Database? Function() _getActiveDb;

  @override
  Future<void> backup({
    required String sourceDbPath,
    required String targetRoot,
  }) async {
    // 1) Validate target drive exists
    final rootDir = Directory(targetRoot);
    if (!await rootDir.exists()) {
      throw Exception('Drive not available: $targetRoot');
    }

    // 2) Ensure Data/ exists on the drive
    final dataDir = Directory(path.join(targetRoot, 'Data'));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    final destPath = path.join(dataDir.path, 'Data.db');

    // 3) If we have an active open DB, create a consistent snapshot
    final db = _getActiveDb();
    if (db != null) {
      await _backupFromOpenDb(db, destPath);
      return;
    }

    // 4) Fallback: copy from the source path (may fail if locked)
    await _copyFileBackup(sourceDbPath, destPath);
  }

  Future<void> _backupFromOpenDb(Database db, String destPath) async {
    // If destination exists, remove it first to avoid partial overwrite issues.
    final destFile = File(destPath);
    if (await destFile.exists()) {
      await destFile.delete();
    }

    // Try SQLite snapshot mechanism via VACUUM INTO (consistent backup).
    // This works only if the SQLite library supports it.
    try {
      final escaped = destPath.replaceAll("'", "''");
      db.execute("VACUUM INTO '$escaped';");
      return;
    } catch (_) {
      // Fall through to a safer file-copy fallback, or you can implement
      // sqlite3's native backup API here if your package exposes it.
    }

    // Last resort: if VACUUM INTO isn't available, attempt a checkpoint and copy.
    // This is better than raw copy, but still can be blocked by file locks.
    try {
      db.execute('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {
      // ignore
    }

    // If your DB is in WAL mode, the -wal and -shm files may matter.
    // Here we copy the main file only; see note below if you use WAL.
    throw Exception(
      'Could not create a safe snapshot from open DB (VACUUM INTO not available). '
      'Consider enabling a snapshot method (SQLite backup API) for your sqlite3 version.',
    );
  }

  Future<void> _copyFileBackup(String sourceDbPath, String destPath) async {
    final src = File(sourceDbPath);
    if (!await src.exists()) {
      throw Exception('Source DB not found: $sourceDbPath');
    }

    // If destination exists, replace it.
    final dest = File(destPath);
    if (await dest.exists()) {
      await dest.delete();
    }

    await src.copy(destPath);
  }
}
