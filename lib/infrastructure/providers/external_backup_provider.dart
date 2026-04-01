import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:io' show Platform;

import 'package:ui_prototype/infrastructure/providers/active_database_connection_provider.dart';

//importing dummy Infrastructure used when Platform is MAC-OS
import 'package:ui_prototype/infrastructure/backup/dummies/dummy_backup_writer.dart';
import 'package:ui_prototype/infrastructure/backup/dummies/dummy_drive_discovery.dart';
import 'package:ui_prototype/infrastructure/backup/dummies/dummy_drive_selection_repo.dart';

//importing use cases
import 'package:ui_prototype/application/backup/usecases/discover_drives.dart';
import 'package:ui_prototype/application/backup/usecases/get_backup_targets.dart';
import 'package:ui_prototype/application/backup/usecases/select_drives.dart';
import 'package:ui_prototype/application/backup/usecases/write_backup.dart';
import 'package:ui_prototype/application/backup/usecases/auto_select_backups.dart';

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

final backupWriterProvider = Provider<BackupWriter>((ref) {

  if(Platform.isWindows) {
    return DbBackupWriter(
      getActiveDb: () => ref.read(activeDatabaseConnectionProvider),
    );
  } else {
    return DummyBackupWriter();
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
  final writer = ref.read(backupWriterProvider);
  final repo = ref.read(driveSelectionRepoProvider);
  final discoverer = ref.read(driveDiscoveryProvider);

  return WriteBackup(writer, repo, discoverer);
});

final autoSelectBackupTargetsProvider = Provider<AutoSelectBackups>((ref) {
  final discoverer = ref.read(driveDiscoveryProvider);
  final repo = ref.read(driveSelectionRepoProvider);

  return AutoSelectBackups(discoverer, repo);
});
// ---------------------- WIRING COMPLETE -----------------------------------


