import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:ui_prototype/application/backup/dtos/backup_request.dart';
import 'package:ui_prototype/application/backup/dtos/backup_target.dart';
import 'package:ui_prototype/infrastructure/backup/crab_cakes_backup_planner.dart';

void main() {
  group('CrabCakesBackupPlanner', () {
    late Directory tempDrive;
    late CrabCakesBackupPlanner planner;

    setUp(() {
      tempDrive = Directory.systemTemp.createTempSync(
        'crab_cakes_backup_planner_test_',
      );

      planner = CrabCakesBackupPlanner();
    });

    tearDown(() {
      if (tempDrive.existsSync()) {
        tempDrive.deleteSync(recursive: true);
      }
    });

    BackupRequest request({
      String projectId = 'project-123',
      String projectName = 'Colorado River Study',
      String sourceDbPath = 'C:/source/project.sqlite',
      bool includeTextExport = true,
      DateTime? createdAt,
      String? baseTable,
      String? exportDelimiter,
    }) {
      return BackupRequest(
        projectId: projectId,
        projectName: projectName,
        sourceDbPath: sourceDbPath,
        includeTextExport: includeTextExport,
        createdAt: createdAt ?? DateTime(2026, 5, 3, 12),
        baseTable: baseTable,
        exportDelimiter: exportDelimiter,
      );
    }

    BackupTarget target({
      String id = 'drive-1',
      String? drivePath,
    }) {
      return BackupTarget(
        id,
        drivePath ?? tempDrive.path,
      );
    }

    test('creates CRABCAKES backup root directory', () async {
      final plan = await planner.prepareBackup(
        request(),
        target(),
      );

      expect(plan.backupRootPath, path.join(tempDrive.path, 'CRABCAKES'));
      expect(Directory(plan.backupRootPath).existsSync(), isTrue);
    });

    test('creates project root directory', () async {
      final plan = await planner.prepareBackup(
        request(),
        target(),
      );

      expect(Directory(plan.projectRootPath).existsSync(), isTrue);
    });

    test('creates data directory', () async {
      final plan = await planner.prepareBackup(
        request(),
        target(),
      );

      expect(plan.dataDir, path.join(plan.projectRootPath, 'data'));
      expect(Directory(plan.dataDir).existsSync(), isTrue);
    });

    test('creates export directory', () async {
      final plan = await planner.prepareBackup(
        request(),
        target(),
      );

      expect(plan.exportDir, path.join(plan.projectRootPath, 'export'));
      expect(Directory(plan.exportDir).existsSync(), isTrue);
    });

    test('sets database backup path inside data directory', () async {
      final plan = await planner.prepareBackup(
        request(),
        target(),
      );

      expect(plan.backupDbPath, path.join(plan.dataDir, 'data.sqlite'));
    });

    test('sets text export path inside export directory', () async {
      final plan = await planner.prepareBackup(
        request(),
        target(),
      );

      expect(plan.textExportPath, path.join(plan.exportDir, 'data.txt'));
    });

    test('sets manifest path inside project root directory', () async {
      final plan = await planner.prepareBackup(
        request(),
        target(),
      );

      expect(
        plan.manifestPath,
        path.join(plan.projectRootPath, 'backup_manifest.json'),
      );
    });

    test('project folder includes sanitized project name and project id', () async {
      final plan = await planner.prepareBackup(
        request(
          projectName: 'Colorado River Study',
          projectId: 'project-123',
        ),
        target(),
      );

      expect(
        path.basename(plan.projectRootPath),
        'Colorado_River_Study_project-123',
      );
    });

    test('replaces spaces in project name with underscores', () async {
      final plan = await planner.prepareBackup(
        request(
          projectName: 'My Cool Project',
          projectId: 'abc',
        ),
        target(),
      );

      expect(path.basename(plan.projectRootPath), 'My_Cool_Project_abc');
    });

    test('trims project name and project id before building folder name', () async {
      final plan = await planner.prepareBackup(
        request(
          projectName: '  My Project  ',
          projectId: '  abc  ',
        ),
        target(),
      );

      expect(path.basename(plan.projectRootPath), 'My_Project_abc');
    });

    test('collapses repeated whitespace into a single underscore', () async {
      final plan = await planner.prepareBackup(
        request(
          projectName: 'My     Cool\tProject',
          projectId: 'abc',
        ),
        target(),
      );

      expect(path.basename(plan.projectRootPath), 'My_Cool_Project_abc');
    });

    test('replaces invalid filename characters in project name', () async {
      final plan = await planner.prepareBackup(
        request(
          projectName: r'Bad<Project>Name:"/\|?*',
          projectId: 'abc',
        ),
        target(),
      );

      expect(path.basename(plan.projectRootPath), 'Bad_Project_Name________abc');
    });

    test('replaces invalid filename characters in project id', () async {
      final plan = await planner.prepareBackup(
        request(
          projectName: 'Project',
          projectId: r'id:"/\|?*',
        ),
        target(),
      );

      expect(path.basename(plan.projectRootPath), 'Project_id_______');
    });

    test('uses unnamed_project when project name becomes empty after trim', () async {
      final plan = await planner.prepareBackup(
        request(
          projectName: '   ',
          projectId: 'abc',
        ),
        target(),
      );

      expect(path.basename(plan.projectRootPath), 'unnamed_project_abc');
    });

    test('uses unnamed_project when project id becomes empty after trim', () async {
      final plan = await planner.prepareBackup(
        request(
          projectName: 'Project',
          projectId: '   ',
        ),
        target(),
      );

      expect(path.basename(plan.projectRootPath), 'Project_unnamed_project');
    });

    test('invalid-only project name becomes underscores, not unnamed_project', () async {
      final plan = await planner.prepareBackup(
        request(
          projectName: r'<>:"/\|?*',
          projectId: 'abc',
        ),
        target(),
      );

      expect(path.basename(plan.projectRootPath), '__________abc');
    });

    test('uses target drive path as root for backup layout', () async {
      final customDrive = Directory(path.join(tempDrive.path, 'custom_drive'));
      customDrive.createSync(recursive: true);

      final plan = await planner.prepareBackup(
        request(),
        target(drivePath: customDrive.path),
      );

      expect(
        plan.backupRootPath,
        path.join(customDrive.path, 'CRABCAKES'),
      );

      expect(Directory(plan.backupRootPath).existsSync(), isTrue);
    });

    test('prepareBackup is idempotent for same request and target', () async {
      final req = request();
      final backupTarget = target();

      final firstPlan = await planner.prepareBackup(req, backupTarget);
      final secondPlan = await planner.prepareBackup(req, backupTarget);

      expect(secondPlan.backupRootPath, firstPlan.backupRootPath);
      expect(secondPlan.projectRootPath, firstPlan.projectRootPath);
      expect(secondPlan.dataDir, firstPlan.dataDir);
      expect(secondPlan.exportDir, firstPlan.exportDir);
      expect(secondPlan.backupDbPath, firstPlan.backupDbPath);
      expect(secondPlan.textExportPath, firstPlan.textExportPath);
      expect(secondPlan.manifestPath, firstPlan.manifestPath);
    });

    test('prepareBackup does not delete existing files in project root', () async {
      final req = request();
      final backupTarget = target();

      final firstPlan = await planner.prepareBackup(req, backupTarget);

      final markerFile = File(path.join(firstPlan.projectRootPath, 'marker.txt'));
      markerFile.writeAsStringSync('do not delete');

      await planner.prepareBackup(req, backupTarget);

      expect(markerFile.existsSync(), isTrue);
      expect(markerFile.readAsStringSync(), 'do not delete');
    });

    test('prepareBackup does not delete existing files in data directory', () async {
      final req = request();
      final backupTarget = target();

      final firstPlan = await planner.prepareBackup(req, backupTarget);

      final existingDb = File(firstPlan.backupDbPath);
      existingDb.writeAsStringSync('existing db placeholder');

      await planner.prepareBackup(req, backupTarget);

      expect(existingDb.existsSync(), isTrue);
      expect(existingDb.readAsStringSync(), 'existing db placeholder');
    });

    test('prepareBackup does not delete existing files in export directory', () async {
      final req = request();
      final backupTarget = target();

      final firstPlan = await planner.prepareBackup(req, backupTarget);

      final existingExport = File(firstPlan.textExportPath);
      existingExport.writeAsStringSync('existing export placeholder');

      await planner.prepareBackup(req, backupTarget);

      expect(existingExport.existsSync(), isTrue);
      expect(existingExport.readAsStringSync(), 'existing export placeholder');
    });

    test('different project ids create different project roots', () async {
      final firstPlan = await planner.prepareBackup(
        request(projectName: 'Project', projectId: 'one'),
        target(),
      );

      final secondPlan = await planner.prepareBackup(
        request(projectName: 'Project', projectId: 'two'),
        target(),
      );

      expect(firstPlan.projectRootPath, isNot(secondPlan.projectRootPath));
      expect(path.basename(firstPlan.projectRootPath), 'Project_one');
      expect(path.basename(secondPlan.projectRootPath), 'Project_two');
    });

    test('different project names create different project roots', () async {
      final firstPlan = await planner.prepareBackup(
        request(projectName: 'Project One', projectId: 'same-id'),
        target(),
      );

      final secondPlan = await planner.prepareBackup(
        request(projectName: 'Project Two', projectId: 'same-id'),
        target(),
      );

      expect(firstPlan.projectRootPath, isNot(secondPlan.projectRootPath));
      expect(path.basename(firstPlan.projectRootPath), 'Project_One_same-id');
      expect(path.basename(secondPlan.projectRootPath), 'Project_Two_same-id');
    });

    test('target id does not affect path layout', () async {
      final req = request();

      final firstPlan = await planner.prepareBackup(
        req,
        target(id: 'drive-one'),
      );

      final secondPlan = await planner.prepareBackup(
        req,
        target(id: 'drive-two'),
      );

      expect(firstPlan.projectRootPath, secondPlan.projectRootPath);
      expect(firstPlan.backupRootPath, secondPlan.backupRootPath);
    });

    test('includeTextExport does not affect planned paths', () async {
      final firstPlan = await planner.prepareBackup(
        request(includeTextExport: true),
        target(),
      );

      final secondPlan = await planner.prepareBackup(
        request(includeTextExport: false),
        target(),
      );

      expect(firstPlan.textExportPath, secondPlan.textExportPath);
      expect(firstPlan.exportDir, secondPlan.exportDir);
    });

    test('sourceDbPath does not affect planned paths', () async {
      final firstPlan = await planner.prepareBackup(
        request(sourceDbPath: 'C:/source/one.sqlite'),
        target(),
      );

      final secondPlan = await planner.prepareBackup(
        request(sourceDbPath: 'D:/other/two.sqlite'),
        target(),
      );

      expect(firstPlan.projectRootPath, secondPlan.projectRootPath);
      expect(firstPlan.backupDbPath, secondPlan.backupDbPath);
    });

    test('createdAt does not affect planned paths', () async {
      final firstPlan = await planner.prepareBackup(
        request(createdAt: DateTime(2026, 5, 3)),
        target(),
      );

      final secondPlan = await planner.prepareBackup(
        request(createdAt: DateTime(2030, 1, 1)),
        target(),
      );

      expect(firstPlan.projectRootPath, secondPlan.projectRootPath);
      expect(firstPlan.manifestPath, secondPlan.manifestPath);
    });

    test('baseTable does not affect planned paths', () async {
      final firstPlan = await planner.prepareBackup(
        request(baseTable: 'Specimen'),
        target(),
      );

      final secondPlan = await planner.prepareBackup(
        request(baseTable: 'Trip'),
        target(),
      );

      expect(firstPlan.projectRootPath, secondPlan.projectRootPath);
      expect(firstPlan.backupDbPath, secondPlan.backupDbPath);
      expect(firstPlan.textExportPath, secondPlan.textExportPath);
    });

    test('exportDelimiter does not affect planned paths', () async {
      final firstPlan = await planner.prepareBackup(
        request(exportDelimiter: ','),
        target(),
      );

      final secondPlan = await planner.prepareBackup(
        request(exportDelimiter: '\t'),
        target(),
      );

      expect(firstPlan.projectRootPath, secondPlan.projectRootPath);
      expect(firstPlan.textExportPath, secondPlan.textExportPath);
    });

    test('throws FileSystemException when target drive path is an existing file', () async {
      final fakeDriveFile = File(path.join(tempDrive.path, 'not_a_directory'));
      fakeDriveFile.writeAsStringSync('I am a file, not a directory');

      await expectLater(
        () => planner.prepareBackup(
          request(),
          target(drivePath: fakeDriveFile.path),
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('plan paths are nested consistently', () async {
      final plan = await planner.prepareBackup(
        request(),
        target(),
      );

      expect(
        path.dirname(plan.projectRootPath),
        path.join(plan.backupRootPath, 'projects'),
      );

      expect(path.dirname(plan.dataDir), plan.projectRootPath);
      expect(path.dirname(plan.exportDir), plan.projectRootPath);
      expect(path.dirname(plan.backupDbPath), plan.dataDir);
      expect(path.dirname(plan.textExportPath), plan.exportDir);
      expect(path.dirname(plan.manifestPath), plan.projectRootPath);
    });
  });
}