import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

//importing access to the main database provider
//import 'package:ui_prototype/presentation/providers/project_database_provider.dart';
import 'package:ui_prototype/presentation/providers/flex_form_provider.dart';


//importing use cases
import 'package:ui_prototype/application/backup/usecases/discover_drives.dart';
import 'package:ui_prototype/application/backup/usecases/get_backup_targets.dart';
import 'package:ui_prototype/application/backup/usecases/select_drives.dart';
import 'package:ui_prototype/application/backup/usecases/write_backup.dart';

//importing interfaces
import 'package:ui_prototype/application/backup/interfaces/backup_writer.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_discovery.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_selection_repo.dart';

//importing concrete infrastructure implementations
import 'package:ui_prototype/infrastructure/backup/backup_settings_db.dart';
import 'package:ui_prototype/infrastructure/backup/db_backup_writer.dart';
import 'package:ui_prototype/infrastructure/backup/drift_drive_selection_repo.dart';
import 'package:ui_prototype/infrastructure/backup/win32_drive_discovery.dart';

//------------------------------------------------------------------------------------


//Wiring INFRASTRUCTURE providers
// final backupSettingsDbProvider = Provider<BackupSettingsDb>((ref) {
//   //constructing the concrete backup settings database
//   return BackupSettingsDb();
// });
final backupSettingsDbProvider = Provider<BackupSettingsDb>((ref) {
  final db = BackupSettingsDb();
  ref.onDispose(() => db.close());
  return db;
});

final driveDiscoveryProvider = Provider<DriveDiscovery>((ref) {
  // Constructing the concrete discovery implementation
  return Win32DriveDiscovery();
});

final driveSelectionRepoProvider = Provider<DriveSelectionRepository>((ref) {
  final db = ref.read(backupSettingsDbProvider);
  
  //constructing the concrete drive repo implementation
  return DriftDriveSelectionRepository(db);
});

//Dont know what to do with tempDirPath :/ FIX!
final backupWriterProvider = Provider<BackupWriter>((ref) {
  // copy-by-path writer: no snapshotter/tempDir needed
  return DbBackupWriter();
});

/// Provides the path to the active project's SQLite DB file.
final currentProjectDbPathProvider = Provider<String>((ref) {
  final projectAsync = ref.watch(currentFlexProjectProvider);

  return projectAsync.when(
    loading: () => throw StateError('Project is still loading'),
    error: (e, st) => throw StateError('Failed to load project: $e'),
    data: (project) {
      if (project == null) throw StateError('No active project loaded');
      return project.dbPath;
    },
  );
});


//Wiring USE CASE providers (which read the infra providers)
final discoverDevicesProvider = Provider<DiscoverDrives>((ref) {
  final discovery = ref.read(driveDiscoveryProvider);

  return DiscoverDrives(discovery);
});

final getBackupTargetsProvider = Provider<GetBackupTargets>((ref) {
  final repo = ref.read(driveSelectionRepoProvider);

  return GetBackupTargets(repo);
});

final selectDrivesProvider = Provider<SelectDrives>((ref) {
  final repo = ref.read(driveSelectionRepoProvider);

  return SelectDrives(repo);
});

final writeBackupProvider = Provider<WriteBackup>((ref) {
  final writer = ref.read(backupWriterProvider);
  final repo = ref.read(driveSelectionRepoProvider);
  final discoverer = ref.read(driveDiscoveryProvider);

  return WriteBackup(writer, repo, discoverer);
});
// ---------------------- WIRING COMPLETE -----------------------------------


