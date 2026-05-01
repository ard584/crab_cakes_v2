import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/application/backup/interfaces/backup_exporter.dart';


//importing supporting provider files
import 'package:ui_prototype/infrastructure/providers/active_database_connection_provider.dart';
import 'package:ui_prototype/infrastructure/providers/app_db_provider.dart';

import 'dart:io' show Platform;


//importing dummy Infrastructure used when Platform is MAC-OS
import 'package:ui_prototype/infrastructure/backup/dummies/dummy_backup_writer.dart';
import 'package:ui_prototype/infrastructure/backup/dummies/dummy_drive_discovery.dart';
import 'package:ui_prototype/infrastructure/backup/dummies/dummy_drive_selection_repo.dart';
import 'package:ui_prototype/infrastructure/backup/dummies/dummy_manifest_writer.dart';

//importing use cases
import 'package:ui_prototype/application/backup/usecases/discover_drives.dart';
import 'package:ui_prototype/application/backup/usecases/get_backup_targets.dart';
import 'package:ui_prototype/application/backup/usecases/select_drives.dart';
import 'package:ui_prototype/application/backup/usecases/write_backup.dart';
import 'package:ui_prototype/application/backup/usecases/auto_select_backups.dart';

//importing app-level dtos
import 'package:ui_prototype/application/backup/dtos/backup_request.dart';

//importing interfaces
import 'package:ui_prototype/application/backup/interfaces/drive_discovery.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_selection_repo.dart';
import 'package:ui_prototype/application/backup/interfaces/backup_manifest_writer.dart';
import 'package:ui_prototype/application/backup/interfaces/db_backup_writer.dart';
import 'package:ui_prototype/application/backup/interfaces/backup_planner.dart';

//importing concrete infrastructure implementations
import 'package:ui_prototype/infrastructure/backup/backup_settings_db.dart';
import 'package:ui_prototype/infrastructure/backup/sqlite_db_backup_writer.dart';
import 'package:ui_prototype/infrastructure/backup/drift_drive_selection_repo.dart';
import 'package:ui_prototype/infrastructure/backup/win32_drive_discovery.dart';
import 'package:ui_prototype/infrastructure/backup/json_manifest_writer.dart';
import 'package:ui_prototype/infrastructure/backup/crab_cakes_backup_planner.dart';
import 'package:ui_prototype/infrastructure/backup/sqlite_backup_exporter.dart';

//------------------------------------------------------------------------------------


//Wiring INFRASTRUCTURE providers

final backupExporterProvider = Provider<BackupExporter>((ref) {
  return SqliteBackupExporter();
});

final backupSettingsDbProvider = Provider<BackupSettingsDb>((ref) {
  final db = BackupSettingsDb();
  ref.onDispose(() => db.close());
  return db;
});

final driveDiscoveryProvider = Provider<DriveDiscovery>((ref) {
  // Constructing the concrete discovery implementation
  if(Platform.isWindows) {
    return Win32DriveDiscovery();
  }
  else {
    return DummyDriveDiscovery();
  }
});

final driveSelectionRepoProvider = Provider<DriveSelectionRepository>((ref) {
  final db = ref.read(backupSettingsDbProvider);
  
  //constructing the concrete drive repo implementation
  if(Platform.isWindows) {
    return DriftDriveSelectionRepository(db);
  } else {
    return DummyDriveSelectionRepo();
  }
});

final backupPlannerProvider = Provider<BackupPlanner>((ref) {
  return CrabCakesBackupPlanner();
});

final backupWriterProvider = Provider<DbBackupWriter>((ref) {
  if(Platform.isWindows) {
    return SqliteDbBackupWriter();
  } else {
    return DummyBackupWriter();
  }
});

final backupManifestWriterProvider = Provider<BackupManifestWriter>((ref) {
  if(Platform.isWindows) {
    return JsonManifestWriter();
  } else {
    return DummyManifestWriter();
  }
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
  final backupWriter = ref.read(backupWriterProvider);
  final repo = ref.read(driveSelectionRepoProvider);
  final discoverer = ref.read(driveDiscoveryProvider);
  final planner = ref.read(backupPlannerProvider);
  final manifestWriter = ref.read(backupManifestWriterProvider);
  final backupExporter = ref.read(backupExporterProvider);

  return WriteBackup(
    planner: planner,
    dbBackupWriter: backupWriter,
    manifestWriter: manifestWriter,
    repo: repo,
    discovery: discoverer,
    backupExporter: backupExporter,
  );
});

final autoSelectBackupTargetsProvider = Provider<AutoSelectBackups>((ref) {
  final discoverer = ref.read(driveDiscoveryProvider);
  final repo = ref.read(driveSelectionRepoProvider);

  return AutoSelectBackups(discoverer, repo);
});
// ---------------------- WIRING COMPLETE -----------------------------------

/// Async Notifier that allows a BackupRequest to be built from UI state and
/// backs up the current project's database.
class BackupActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> backupCurrentProject({
    required bool includeTextExport,
    String? baseTable,
    String? exportDelimiter,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final project = ref.read(activeProjectProvider);
      final sourceDbPath = ref.read(activeDatabasePathProvider);

      if (project == null) {
        throw Exception('No active project selected.');
      }

      if (sourceDbPath == null) {
        throw Exception('No active project database path is available.');
      }

      final projectId = base64UrlEncode(project.id);

      final request = BackupRequest(
        projectId: projectId,
        projectName: project.title,
        sourceDbPath: sourceDbPath,
        includeTextExport: includeTextExport,
        createdAt: DateTime.now(),
        baseTable: baseTable,
        exportDelimiter: exportDelimiter,
      );

      await ref.read(writeBackupProvider).execute(request: request);
    });
  }
}

//exposing the class
final backupActionsProvider =
    AsyncNotifierProvider<BackupActionsNotifier, void>(
  BackupActionsNotifier.new,
);